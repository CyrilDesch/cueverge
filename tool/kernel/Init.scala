// @what: cueverge init, a journaled Kyo flow. Scaffold, Claude drafts in the sandbox, vet, a person approves, adopt.
// @invariant: Claude writes only the draft. The frame changes once a person approves its hash.
// @why: the draft is the one stochastic node. A replay vets it again from the journal.
// @ref: @/tool/kernel/README.md
package kernel

import kyo.*

import java.nio.file.{Files, Path as JPath}
import java.security.MessageDigest

// @what: what the scaffold did. The module path and the name of the project travel with it to the later nodes.
// @what: created holds the new files, completed the existing files that the scaffold added lines to.
final case class Scaffold(module: String, name: String, created: Seq[String], completed: Seq[String] = Nil)

// @what: the draft file as Claude left it, and what the run did.
final case class Draft(text: String, generation: Generation)

// @what: a draft that vets. Its value as JSON, and the hash a person approves.
final case class Vetted(hash: String, value: String)

// @what: the files that the approval wrote.
final case class Adopted(files: Seq[String])

object Init:

    val Journal = "init"
    // @what: where Claude writes, inside the CUE module of the project. Its name starts with a dot, so `cue vet ./...` never reads a draft.
    val DraftDir = s"${Project.Folder}/.draft"

    private def sha256(s: String) = MessageDigest.getInstance("SHA-256").digest(s.getBytes("UTF-8")).map("%02x".format(_)).mkString

    def rootOf(o: Options): JPath = JPath.of(o.dir).toAbsolutePath.normalize
    // @what: the CUE module of a project, in the cueverge folder of its repository.
    def module(root: JPath): JPath = root.resolve(Project.Folder)
    def journalDir(root: JPath): String = module(root).resolve(s"gen/journal/$Journal").toString
    def rulesDir(root: JPath): String   = module(root).resolve(s"cogen/journal/$Journal").toString

    def flow(o: Options)(using Frame) =
        val root = rootOf(o)
        Flow.init("init", description = "Make a project of a folder: scaffold, draft the frame with Claude, vet, await a person, adopt.")
            .output("problem", description = "the problem, as the person states it")(_ => o.problem.trim)
            .output("scaffold", description = "the files of a project, created where none exists, without AI") { ctx =>
                Sync.defer(scaffold(root, o.module, ctx.problem)).map { sc =>
                    // @why: the templates are not in the layout of cue fmt, so a new project would fail its first lint.
                    val cue = (sc.created ++ sc.completed).filter(r => r.endsWith(".cue") && !r.startsWith(s"${Project.Folder}/gen/"))
                    Tools.cueFmt(cue.map(r => root.resolve(r).toString)).andThen(sc)
                }
            }
            .output("draft", description = "claude -p in the sandbox runtime: reads the repository, writes only the draft") { ctx =>
                Main.orFail(draft(root, ctx.problem))
            }
            .output("vet", description = "cue vet on the draft, then its hash. A draft that does not vet stops the flow") { ctx =>
                Main.orFail(vet(root, ctx.problem, ctx.draft.text))
            }
            .input[String]("approval", description = "the hash of the draft, as a person approves it with cueverge approve")
            .output("adopted", description = "the approved draft becomes the frame and the intents of the project") { ctx =>
                Main.orFail(adopt(root, ctx.scaffold, ctx.vet, ctx.approval))
            }

    // --- Scaffold ---------------------------------------------------------------

    def scaffold(root: JPath, module: String, problem: String): Scaffold =
        val name = root.getFileName.toString.toLowerCase.replaceAll("[^a-z0-9-]", "-")
        val mod  = existingModule(root).getOrElse(if module.nonEmpty then module else s"cueverge.local/$name")
        val files = Templates.files(mod, name, problem)
        val outcome = files.toSeq.sortBy(_._1).map { (rel, text) =>
            val f = root.resolve(rel)
            if !Files.exists(f) then
                Files.createDirectories(f.getParent): Unit
                Files.writeString(f, text): Unit
                (Some(rel), None)
            // @why: a module that holds the tool in cue.mod/pkg reads it there. A dependency too makes every import of the tool ambiguous.
            else if rel == s"${Project.Folder}/cue.mod/module.cue" && Files.exists(vendored(root)) then (None, None)
            else
                val before = Files.readString(f)
                val after  = Templates.merge(rel, before, text)
                if after == before then (None, None)
                else
                    Files.writeString(f, after): Unit
                    (None, Some(rel))
        }
        Scaffold(mod, name, outcome.flatMap(_._1), outcome.flatMap(_._2))

    // @what: the tool module inside cue.mod/pkg of the project, as the factory itself holds it.
    def vendored(root: JPath): JPath = module(root).resolve("cue.mod/pkg").resolve(Project.Module.stripSuffix("@v0"))

    // @what: the module path of a folder that already is a CUE module. The scaffold keeps it.
    def existingModule(root: JPath): Option[String] =
        val f = module(root).resolve("cue.mod/module.cue")
        if !Files.exists(f) then None
        else "(?m)^module:\\s*\"([^\"@]+)".r.findFirstMatchIn(Files.readString(f)).map(_.group(1))

    // --- Draft ------------------------------------------------------------------

    def draft(root: JPath, problem: String)(using Frame): Draft < (Async & Abort[String]) =
        val dir  = root.resolve(DraftDir)
        val file = dir.resolve("draft.cue")
        for
            p <- Tools.exportedImport(module(root), s"${Project.Module.stripSuffix("@v0")}/frame", "init")
            _ <- Sync.defer {
                Files.createDirectories(dir): Unit
                Files.deleteIfExists(file): Unit
            }
            brief = s"""${p("instructions").str}
                       |
                       |The draft path: $file
                       |
                       |The problem, as the person states it:
                       |
                       |$problem
                       |""".stripMargin
            walls = Sandbox(Seq(dir.toString), Nil, Seq("api.anthropic.com", "*.anthropic.com", "claude.ai", "*.claude.ai"))
            allowed = Seq("Read", "Glob", "Grep", s"Write(/$file)", s"Edit(/$file)")
            g <- Sync.defer(java.lang.System.err.println(s"  init | claude ${p("model").str}, ${p("maxBudgetUsd").num} USD at most, writes $file"))
                .andThen(Agent.headless(p("model").str, p("maxBudgetUsd").num, allowed, walls, brief, journalDir(root)))
            text <- Sync.defer(if Files.exists(file) then Files.readString(file) else "")
        yield Draft(text, g)

    // --- Vet --------------------------------------------------------------------

    // @what: the check the kernel adds to a draft. The problem must stay as the person stated it, and the shapes of the tool hold.
    def checkFile(problem: String): String =
        s"""// @generated: the check of an init draft, written by the kernel next to the draft. Do not edit.
           |// @ref: @/tool/kernel/Init.scala
           |// @ref: $$> cueverge init -replay <execution>
           |package draft
           |
           |import f "${Project.Module.stripSuffix("@v0")}/frame"
           |
           |problem: ${ujson.Str(problem).render()}
           |
           |let O = objectives
           |let C = constraints
           |let I = intents
           |check: {
           |	frame: f.#Frame & {"problem": problem, "objectives": O, "constraints": C}
           |	intents: f.#Intents & {"objectives": O, "intents": I}
           |}
           |""".stripMargin

    def vet(root: JPath, problem: String, text: String)(using Frame): Vetted < (Async & Abort[String]) =
        val dir = root.resolve(DraftDir)
        if text.trim.isEmpty then Abort.fail("init: Claude wrote no draft")
        else
            Sync.defer {
                Files.createDirectories(dir): Unit
                // @why: written back from the journal, so that a replay vets what was drafted, not what the folder holds now.
                Files.writeString(dir.resolve("draft.cue"), text): Unit
                Files.writeString(dir.resolve("check.cue"), checkFile(problem)): Unit
            }.andThen(Tools.vet(dir.toString)).map {
                case Left(report) => Abort.fail(s"init: the draft does not vet\n${Main.clip(report, 2000)}")
                case Right(()) =>
                    Tools.exported(dir.toString, """{"problem": problem, "objectives": objectives, "constraints": constraints, "intents": intents}""", Nil)
                        .map { v =>
                            val json = ujson.write(v)
                            Vetted(sha256(json).take(12), json)
                        }
            }

    // --- Adopt ------------------------------------------------------------------

    def adopt(root: JPath, s: Scaffold, v: Vetted, approval: String)(using Frame): Adopted < (Async & Abort[String]) =
        if approval != v.hash then Abort.fail(s"init: the approval names ${approval}, the draft is ${v.hash}")
        else
            val value = ujson.read(v.value)
            val frame = ujson.Obj("problem" -> value("problem"), "objectives" -> value("objectives"), "constraints" -> value("constraints"))
            val files = Seq(
                s"${Project.Folder}/frame/frame.cue"     -> Templates.frame(frame, v.hash),
                s"${Project.Folder}/intents/intents.cue" -> Templates.intents(s.module, value("intents"), v.hash)
            )
            Sync.defer(files.foreach((rel, text) => Files.writeString(root.resolve(rel), text): Unit))
                .andThen(Tools.cueFmt(files.map((rel, _) => root.resolve(rel).toString)))
                .andThen(Tools.vetAll(module(root)).map {
                    case Left(report) => Abort.fail(s"init: the adopted frame does not vet\n${Main.clip(report, 2000)}")
                    case Right(())    => Adopted(files.map(_._1))
                })

    // --- Commands ---------------------------------------------------------------

    def run(o: Options)(using Frame): Unit < (Async & Abort[String]) =
        val root = rootOf(o)
        if o.replay.isEmpty && o.problem.trim.length < 20 then
            Abort.fail("init: state the problem with -problem <text> or -problem-file <file>, in 20 characters at least")
        else
            val seeds: Maybe[(String, Dict[String, FlowStore.FieldData])] < (Async & Abort[String]) =
                if o.replay.isEmpty then Absent
                else
                    for
                        recorded <- CueFlowStore.fields(journalDir(root), o.replay)
                        stamp    <- Clock.now.map(_.toJava.toEpochMilli)
                    yield Present((s"${o.replay}-replay-$stamp", recorded.filter((name, _) => Set("problem", "scaffold", "draft").contains(name))))
            Sync.defer(Files.createDirectories(root)).andThen(seeds).map { s =>
                Main.runFlowIn(journalDir(root), rulesDir(root), flow(o), "init", s, waiting)((store, eid) =>
                    for
                        sc <- store.getField[Scaffold](eid, "scaffold").map(Main.need(_, "scaffold"))
                        d  <- store.getField[Draft](eid, "draft").map(Main.need(_, "draft"))
                        v  <- store.getField[Vetted](eid, "vet").map(Main.need(_, "vet"))
                    yield (eid.value, sc, d, v)
                ).map { (eid, sc, d, v) =>
                    val g = d.generation
                    Console.printLine(
                        s"""init ${eid}: ${sc.created.size} file(s) created, ${sc.completed.size} completed (${sc.completed.mkString(", ")}), module ${sc.module}
                           |draft: ${g.outcome}, ${g.turns} turns, ${f"${g.costUsd}%.2f"} USD, ${g.seconds} s
                           |${Main.clip(g.result, 600)}
                           |
                           |The draft vets. Read it: ${root.resolve(DraftDir).resolve("draft.cue")}
                           |approve: cueverge approve ${v.hash}${if o.dir == "." then "" else s" ${o.dir}"}""".stripMargin)
                }
            }

    // @what: init stops when its draft vets and the flow waits for the approval node.
    def waiting(fields: Set[String], status: Flow.Status): Boolean = fields.contains("vet") || status == Flow.Status.Completed

    // @what: cueverge approve. An initiative folder approves the intent of its last generation, a project folder its pending init.
    def approve(o: Options)(using Frame): Unit < (Async & Abort[String]) =
        if Files.exists(JPath.of(o.dir, "initiative.cue")) then
            Tools.set(o.dir, "approval.cue", Main.pkg, "approval", ujson.Obj("intent" -> o.hash))
                .andThen(Console.printLine(s"approve: ${o.dir}/approval.cue names the intent ${o.hash}. Next: cueverge round ${o.dir}"))
        else
            val root = Project.repo(Project.root(o.dir))
            val journal = journalDir(root)
            Tools.read(journal, "executions").map { ex =>
                val all = ex.obj.keySet
                val pending = ex.obj.toSeq.collect {
                    case (id, e) if e.obj.get("flow").exists(_.str == "init") &&
                        e("fields").obj.get("vet").exists(_("value")("hash").str == o.hash) &&
                        !all.contains(s"$id-approval") => id
                }.sorted
                pending.lastOption match
                    case None => Abort.fail(s"approve: no init draft with hash ${o.hash} awaits a person in $journal")
                    case Some(id) =>
                        for
                            recorded <- CueFlowStore.fields(journal, id)
                            tag      <- Main.need(recorded.get("problem"), s"the problem of $id").map(fd => ujson.read(Json.encode(fd)).obj("tag"))
                            approval <- Abort.get(Json.decode[FlowStore.FieldData](
                                ujson.Obj("value" -> ujson.Str(ujson.Str(o.hash).render()), "tag" -> tag).render()
                            ).mapFailure(e => s"approve: $e"))
                            seeded = recorded.filter((name, _) => name != "adopted").update("approval", approval)
                            adopted <- Main.runFlowIn(journal, rulesDir(root), flow(o.copy(dir = root.toString)), "init",
                                Present((s"$id-approval", seeded)), Main.done)((store, eid) =>
                                store.getField[Adopted](eid, "adopted").map(Main.need(_, "adopted")))
                            _ <- Console.printLine(s"approve: the draft ${o.hash} of $id is the frame of the project (${adopted.files.mkString(", ")})")
                        yield ()
            }
end Init
