// @what: copies the exports of a project into the gen module of this base, with their source and their hash.
// @why: the factory measures its experiments on a project that imports it. Importing the project back would be a cycle.
// @ref: $> cueverge capture project <project-dir> <name>
package kernel

import kyo.*

import java.nio.file.{Files, Path as JPath}
import java.security.MessageDigest
import scala.jdk.CollectionConverters.*

object ProjectCapture:

    private def sha256(b: Array[Byte]) = MessageDigest.getInstance("SHA-256").digest(b).map("%02x".format(_)).mkString

    private def list(dir: JPath, suffix: String): Seq[JPath] =
        if !Files.isDirectory(dir) then Nil
        else
            val s = Files.list(dir)
            try s.iterator.asScala.filter(f => Files.isRegularFile(f) && f.getFileName.toString.endsWith(suffix)).toSeq.sorted
            finally s.close()

    // @what: the folders a capture mirrors, relative to a module root, with the suffix of the files it copies.
    private def mirrored(name: String): Seq[(String, String)] =
        Seq(s"gen/journal/$name" -> ".export.cue", s"gen/runs/$name" -> ".gen.cue")

    private def header(what: String) =
        s"// @generated: $what Do not edit.\n" +
            "// @ref: @/tool/kernel/ProjectCapture.scala\n" +
            "// @ref: $> cueverge capture check\n"

    // @what: the commit of the project, from jj when the project uses it, else from git.
    private def commit(root: JPath)(using Frame): String < Async =
        val jj = Cmd(Seq("jj", "--ignore-working-copy", "-R", root.toString, "log", "-r", "@", "--no-graph", "-T", "commit_id"), 30000)
        val git = Cmd(Seq("git", "-C", root.toString, "rev-parse", "HEAD"), 30000)
        Run.run(jj, "").map(a => if a.exit == 0 && a.out.trim.nonEmpty then a.out.trim: String < Async else Run.run(git, "").map(_.out.trim))

    def capture(projectDir: String, name: String)(using Frame): Unit < (Async & Abort[String]) =
        val base = Project.root(".")
        val proj = Project.root(projectDir)
        if !name.matches("[a-z0-9][a-z0-9-]*") then Abort.fail(s"bad name: $name")
        else if base.toString == proj.toString then Abort.fail("capture project: the project is this base")
        else
            for
                values <- Tools.exported(proj.resolve(s"initiatives/$name").toString, """{"initiative": initiative, "sealed": sealed}""", Nil)
                sha    <- commit(Project.repo(proj))
                remote <- Run.run(Cmd(Seq("git", "-C", Project.repo(proj).toString, "remote", "get-url", "origin"), 30000), "").map(_.out.trim)
                now    <- Clock.now.map(_.toJava.truncatedTo(java.time.temporal.ChronoUnit.SECONDS).toString)
                files <- Sync.defer {
                    val copied = mirrored(name).flatMap { (rel, suffix) =>
                        val (from, to) = (proj.resolve(rel), base.resolve(rel))
                        Files.createDirectories(to): Unit
                        val want = list(from, suffix)
                        // @why: a capture is a snapshot. A file the project no longer has goes away here too.
                        list(to, suffix).filterNot(f => want.exists(_.getFileName.toString == f.getFileName.toString)).foreach(Files.delete)
                        want.map { f =>
                            Files.copy(f, to.resolve(f.getFileName), java.nio.file.StandardCopyOption.REPLACE_EXISTING): Unit
                            s"$rel/${f.getFileName}"
                        }
                    }
                    val dir = base.resolve(s"gen/project/$name")
                    Files.createDirectories(dir): Unit
                    Files.writeString(dir.resolve("project.gen.cue"),
                        header("the initiative and the seal of a captured project.") + "package project\n\n" +
                            s"initiative: ${ujson.write(values("initiative"), indent = 1)}\n\nsealed: ${ujson.write(values("sealed"), indent = 1)}\n"): Unit
                    copied :+ s"gen/project/$name/project.gen.cue"
                }
                _ <- Sync.defer {
                    val hashes = files.sorted.map(f => f -> ujson.Str(sha256(Files.readAllBytes(base.resolve(f)))))
                    Files.writeString(base.resolve(s"gen/project/$name/source.gen.cue"),
                        header("where a captured project comes from, and the hash of every captured file.") + "package project\n\n" +
                            s"source: ${ujson.write(ujson.Obj("repo" -> remote, "commit" -> sha, "captured" -> now), indent = 1)}\n\n" +
                            s"files: ${ujson.write(ujson.Obj.from(hashes), indent = 1)}\n"): Unit
                }
                _ <- Tools.fmt(Seq(base.resolve(s"gen/project/$name/project.gen.cue").toString, base.resolve(s"gen/project/$name/source.gen.cue").toString))
                // @why: cue fmt rewrites project.gen.cue, so its hash is taken again after it.
                _ <- rehash(base, name)
                _ <- Console.printLine(s"capture: $name, ${files.size} file(s) from ${proj.getFileName} at ${sha.take(12)}")
            yield ()

    private def rehash(base: JPath, name: String)(using Frame): Unit < (Async & Abort[String]) =
        Sync.defer {
            val f    = base.resolve(s"gen/project/$name/source.gen.cue")
            val text = Files.readString(f)
            val rel  = s"gen/project/$name/project.gen.cue"
            val now  = sha256(Files.readAllBytes(base.resolve(rel)))
            val line = s"(?m)^(\\s*\"${java.util.regex.Pattern.quote(rel)}\":\\s*)\"[0-9a-f]+\"".r
            Files.writeString(f, line.replaceAllIn(text, m => java.util.regex.Matcher.quoteReplacement(m.group(1) + "\"" + now + "\""))): Unit
        }

    // @invariant: every captured file has the hash its manifest gives, and every file of a captured folder is in the manifest.
    def check(baseDir: String)(using Frame): Unit < (Async & Abort[String]) =
        val base = Project.root(baseDir)
        val names =
            val d = base.resolve("gen/project")
            if !Files.isDirectory(d) then Nil
            else
                val s = Files.list(d)
                try s.iterator.asScala.filter(Files.isDirectory(_)).map(_.getFileName.toString).toSeq.sorted finally s.close()
        Kyo.foreach(names) { name =>
            Tools.exported(base.resolve(s"gen/project/$name").toString, "files", Nil).map { files =>
                Sync.defer {
                    val listed = files.obj.toSeq.map((f, h) => f -> h.str).toMap
                    val bad = listed.toSeq.sorted.flatMap { (f, h) =>
                        val p = base.resolve(f)
                        if !Files.exists(p) then Some(s"$f: listed, missing")
                        else if sha256(Files.readAllBytes(p)) != h then Some(s"$f: differs from its captured hash")
                        else None
                    }
                    val extra = mirrored(name).flatMap((rel, suffix) => list(base.resolve(rel), suffix).map(f => s"$rel/${f.getFileName}"))
                        .filterNot(listed.contains).map(f => s"$f: not in the capture of $name")
                    (bad ++ extra, listed.size)
                }
            }
        }.map { results =>
            val bad = results.flatMap(_._1)
            if bad.isEmpty then Console.printLine(s"capture: ${names.size} project(s), ${results.map(_._2).sum} file(s) match their hash")
            else Abort.fail(bad.mkString("\n"))
        }
end ProjectCapture
