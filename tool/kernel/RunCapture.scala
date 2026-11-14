// @what: imports the runs of the Go kernel as generated CUE, one file per run.
// @invariant: forgetful. It keeps the case, the verdict, the oracle answer and the time.
// @why: these runs predate the Kyo journal. The first experiments have no other export.
// @ref: $> cueverge runs cue-interpreter initiatives/cue-interpreter/runs
package kernel

import kyo.*

import java.io.ByteArrayOutputStream
import java.nio.file.{Files, Path as JPath}
import java.security.MessageDigest
import java.util.zip.{GZIPInputStream, GZIPOutputStream}
import scala.jdk.CollectionConverters.*

object RunCapture:

    private val CasePrefix = "initiatives/cue-interpreter/cases/"

    private def sha256(b: Array[Byte]) = MessageDigest.getInstance("SHA-256").digest(b).map("%02x".format(_)).mkString

    // @invariant: the rendered file depends only on the raw bytes and the run name.
    def render(raw: Array[Byte], run: String): String =
        val cases = new String(raw, "UTF-8").linesIterator.filter(_.trim.nonEmpty).map(ujson.read(_)).map { l =>
            val o = ujson.Obj("verdict" -> l("verdict").str, "oracleOk" -> l("oracleOk").bool)
            l.obj.get("ms").foreach(m => o("ms") = m.num)
            l("case").str.stripPrefix(CasePrefix) -> o
        }.toSeq
        "// @generated: the verdicts of one run of the Go kernel. Do not edit.\n" +
            "// @ref: @/tool/kernel/RunCapture.scala\n" +
            "// @ref: $> cueverge capture check\n" +
            "package runs\n\n" +
            s"runs: ${ujson.Str(run).render()}: ${ujson.write(ujson.Obj("sha256" -> sha256(raw), "cases" -> ujson.Obj.from(cases)), indent = 1)}\n"

    private def gzip(b: Array[Byte]): Array[Byte] =
        val out = ByteArrayOutputStream()
        val z   = GZIPOutputStream(out)
        z.write(b); z.close()
        out.toByteArray

    private def gunzip(f: JPath): Array[Byte] =
        val in = GZIPInputStream(Files.newInputStream(f))
        try in.readAllBytes() finally in.close()

    // @what: the file name of a run. The source folder and the file stem, joined, since stems repeat across folders.
    private def fileOf(run: String) = run.replace('/', '_')

    def capture(kbDir: String, name: String, sources: Seq[String])(using Frame): Unit < (Async & Abort[String]) =
        Sync.defer {
            val dir = JPath.of(kbDir).resolve("gen/runs").resolve(name)
            Files.createDirectories(dir.resolve("raw")): Unit
            val runs = sources.flatMap { src =>
                val s = Files.list(JPath.of(src))
                try s.iterator.asScala.filter(_.toString.endsWith(".jsonl")).toSeq.sorted finally s.close()
            }.map { f =>
                val run = s"${f.getParent.getFileName}/${f.getFileName.toString.stripSuffix(".jsonl")}"
                val raw = Files.readAllBytes(f)
                Files.write(dir.resolve(s"raw/${fileOf(run)}.jsonl.gz"), gzip(raw)): Unit
                Files.writeString(dir.resolve(s"${fileOf(run)}.gen.cue"), render(raw, run)): Unit
                run
            }
            s"runs: ${runs.size} run(s) of $name"
        }.map(Console.printLine(_))

    // @invariant: every run extracts again to the same bytes, so no hand edited a generated run.
    def check(kbDir: String)(using Frame): Unit < (Async & Abort[String]) =
        Sync.defer {
            val root = JPath.of(kbDir).resolve("gen/runs")
            val raws =
                if !Files.isDirectory(root) then Nil
                else
                    val s = Files.walk(root)
                    try s.iterator.asScala.filter(_.toString.endsWith(".jsonl.gz")).toSeq.sorted finally s.close()
            val bad = raws.flatMap { gz =>
                val dir  = gz.getParent.getParent
                val file = gz.getFileName.toString.stripSuffix(".jsonl.gz")
                val gen  = dir.resolve(s"$file.gen.cue")
                // @why: the run name is in the generated file. Reading it back keeps the folder and stem split exact.
                val have = if Files.exists(gen) then Files.readString(gen) else ""
                val run  = "(?m)^runs: \"([^\"]+)\"".r.findFirstMatchIn(have).map(_.group(1)).getOrElse("")
                if run.nonEmpty && fileOf(run) == file && render(gunzip(gz), run) == have then None
                else Some(s"${root.relativize(gen)}: differs from its raw run")
            }
            (bad, raws.size)
        }.map { (bad, n) =>
            if bad.isEmpty then Console.printLine(s"runs: $n run(s) extract again to the same bytes")
            else Abort.fail(bad.mkString("\n"))
        }
end RunCapture
