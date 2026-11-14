// @what: the entry point of the cueverge CLI, and a round of an initiative as a Kyo Flow. It observes, CUE decides.
// @invariant: every named node is recorded before the next one starts. A decision is a function of what was recorded.
// @ref: @/tool/kernel/README.md

package kernel

import kyo.*

import java.nio.file.{Files, Path as JPath}
import scala.jdk.CollectionConverters.*

final case class Options(
    jobs: Int = 8,
    show: Int = 5,
    filter: String = "",
    only: String = "",
    dir: String = "",
    diagram: Boolean = false,
    replay: String = "",
    agent: Boolean = false,
    exportOnly: Boolean = false,
    capture: List[String] = Nil,
    captureCheck: Boolean = false,
    runs: List[String] = Nil,
    // @what: the subcommand, as Usage lists it.
    command: String = "round",
    // @what: the problem of an init, as the person states it.
    problem: String = "",
    // @what: the module path that init gives a new project.
    module: String = "",
    // @what: the hash a person approves, and the version of the tool for an upgrade.
    hash: String = "",
    version: String = "",
    rest: List[String] = Nil
)

// @what: What the kernel needs of #Initiative: what to run.
final case class Initiative(name: String, glob: String, oracle: Cmd, candidate: Cmd, retries: Int)

// @what: One case to observe. The commands travel with it. A fan-out body sees only its item.
final case class Task(path: String, oracle: Cmd, candidate: Cmd)

// @what: What is kept of one case. Its observations, and a clip of each answer for whoever reads the failures.
final case class Seen(path: String, pair: Pair, oracleText: String, candidateText: String)

// @what: #Round.summary in the factory rules.
// @ref: @/tool/cue/rules/round.rules.cue
final case class Count(verdict: String, n: Int)
final case class Summary(
    cases: Int,
    count: Seq[Count],
    valid: Int,
    validCorrect: Int,
    failing: Seq[String],
    late: Seq[String],
    regressed: Seq[String]
)

// @what: The verdicts of the round, and the observations they were given.
final case class Judgment(verdicts: Map[String, String], summary: Summary, observed: Map[String, Pair])

// @what: #IntentReview in rules/intent.rules.cue, as the runner shows it. Decided in check/, not here.
final case class IntentView(status: String, hash: String, approvedBy: String, goal: String, notFixed: Seq[String], unannounced: Seq[String], excused: Seq[String])

// @what: What `cue vet` said.
final case class Decision(decided: Boolean, holds: Boolean, report: String) derives CanEqual

// @what: What a round recorded, read back from the store.
final case class Recorded(execution: String, initiative: Initiative, observe: Chunk[Seen], retime: Judgment, decision: Decision,
    intent: Maybe[IntentView] = Absent)

final case class KernelError(message: String) extends Exception(message)

object Main extends KyoApp:

    // @what: The files and the package of an initiative.
    val pkg          = "initiative"
    val observedFile = "observed.gen.cue" // written by the kernel each round
    val sealedFile   = "sealed.gen.cue"   // the verdicts of the last round that held
    val checkDir     = "check"            // the decision, in its own package
    val intentFile   = "intent.gen.cue"   // what the last generation claims; cleared when a round seals

    // @what: A tool failure fails the flow.
    def orFail[A](v: A < (Async & Abort[String]))(using Frame): A < Async =
        Abort.recover[String](m => Abort.panic(KernelError(m)))(v)

    // --- The round -----------------------------------------------------------

    def round(o: Options)(using Frame) =
        val dir = o.dir
        Flow.init("round", description = "One round of an initiative: observe, judge with CUE, decide, seal.")
            .output("initiative", description = "initiative.cue, read with cue-extended render") { _ =>
                orFail(readInitiative(dir))
            }
            .output("reference", description = "the verdicts of the last sealed round") { _ =>
                orFail(Tools.read(dir, "sealed")).map(v => v.obj.toMap.map((k, x) => k -> x.str))
            }
            .output("cases", description = "the cases of the round, in path order") { ctx =>
                Sync.defer(glob(ctx.initiative.glob).filter(_.contains(o.filter)))
            }
            .foreach("observe", description = "oracle (cached) and candidate, extracted at once", concurrency = o.jobs)(ctx =>
                ctx.cases.map(Task(_, ctx.initiative.oracle, ctx.initiative.candidate))
            ) { t =>
                for
                    a <- Run.cached(t.oracle, t.path, ".cache/oracle")
                    b <- Run.run(t.candidate, t.path)
                yield Seen(t.path, Pair(Extract(a, false), Extract(b, true)), clip(a.out + a.err, 400), clip(b.out + b.err, 400))
            }
            .loop("retime", Map.empty[String, Pair], -1) { (observed, left, ctx) =>
                // @what: the first iteration judges what was observed. The next ones time the late cases again.
                val current = if left >= 0 then observed else ctx.observe.map(x => x.path -> x.pair).toMap
                val budget  = if left >= 0 then left else ctx.initiative.retries
                orFail(write(dir, current).andThen(judge(dir, current))).map { j =>
                    if budget == 0 || j.summary.late.isEmpty then Loop.done(j)
                    else
                        Kyo.foreach(j.summary.late)(c => Run.run(ctx.initiative.candidate, c).map(a => c -> a.ms)).map { times =>
                            val next = times.foldLeft(current) { case (acc, (c, ms)) =>
                                val p = acc(c)
                                acc.updated(c, p.copy(candidate = p.candidate.copy(ms = p.candidate.ms :+ ms)))
                            }
                            Loop.continue(next, budget - 1)
                        }
                }
            }
            .output("intent", description = "round.intent: does the round hold the declared intent, and who approved it") { _ =>
                orFail(Tools.read(dir, "round.intent")).map { i =>
                    def strings(f: String) = i(f).arr.toSeq.map(_.str)
                    IntentView(i("status").str, i("hash").str, i("approvedBy").str, i("intent")("goal").str,
                        strings("notFixed"), strings("unannounced"), strings("excused"))
                }
            }
            .output("decision", description = "cue vet -c check/: observations & rules & seal, from the record only") { ctx =>
                if o.filter.nonEmpty then Decision(false, false, "filtered round: no decision")
                else
                    // @why: the decision reads files. They are written back from the record first, so a replay decides on what was seen.
                    orFail(write(dir, ctx.retime.observed).andThen(
                        Tools.set(dir, sealedFile, pkg, "sealed", verdictsCue(ctx.reference))
                    )).andThen(
                        Tools.vet(JPath.of(dir, checkDir).toString).map {
                            case Right(()) => Decision(true, true, "")
                            case Left(r)   => Decision(true, false, r)
                        }
                    )
            }
            .step("seal", description = "the round holds: its verdicts become the reference") { ctx =>
                // @what: The claim is spent. The next round starts with no intent.
                if ctx.decision.holds && o.replay.isEmpty then
                    orFail(Tools.set(dir, sealedFile, pkg, "sealed", verdictsCue(ctx.retime.verdicts))
                        .andThen(Tools.set(dir, intentFile, pkg, "intent", ujson.Obj())))
                else Kyo.unit
            }
    end round

    // --- Steps ---------------------------------------------------------------

    def readInitiative(dir: String)(using Frame): Initiative < (Async & Abort[String]) =
        Tools.read(dir, "initiative").map { in =>
            def cmd(v: ujson.Value) = Cmd(v("cmd").arr.toSeq.map(_.str), v("timeoutMs").num.toInt)
            Initiative(in("name").str, in("cases")("glob").str, cmd(in("oracle")), cmd(in("candidate")),
                in("candidate")("timing")("retries").num.toInt)
        }

    def write(dir: String, observed: Map[String, Pair])(using Frame): Unit < (Async & Abort[String]) =
        Tools.set(dir, observedFile, pkg, "observed", ujson.Obj.from(observed.toSeq.sortBy(_._1).map((k, p) => k -> p.toJson)))

    def judge(dir: String, observed: Map[String, Pair])(using Frame): Judgment < (Async & Abort[String]) =
        for
            v <- Tools.read(dir, "round.verdicts")
            s <- Tools.read(dir, "round.summary")
        yield
            def strings(f: String) = s(f).arr.toSeq.map(_.str)
            Judgment(
                v.obj.toMap.map((k, x) => k -> x.str),
                Summary(
                    s("cases").num.toInt,
                    s("count").arr.toSeq.map(c => Count(c("verdict").str, c("n").num.toInt)),
                    s("valid").num.toInt,
                    s("validCorrect").num.toInt,
                    strings("failing"),
                    strings("late"),
                    strings("regressed")
                ),
                observed
            )

    def verdictsCue(v: Map[String, String]): ujson.Value =
        ujson.Obj.from(v.toSeq.sorted.map((k, x) => k -> ujson.Str(x)))

    // --- Entry point ---------------------------------------------------------

    val Usage = """usage: cueverge <command> …
       |  cueverge init [-problem <text> | -problem-file <file>] [-module <path>] [-replay <execution>] [<dir>]   scaffold a project, draft its frame, await approval
       |  cueverge approve <hash> [<initiative-dir>]   approve the pending init draft, or the intent of an initiative
       |  cueverge round [-j N] [-show N] [-filter text] [-verdict v] <initiative-dir>
       |  cueverge agent <initiative-dir>               generate, then round, as the initiative allows
       |  cueverge replay <execution> <initiative-dir>  decide again from the journal, compare
       |  cueverge export <initiative-dir>              write the missing exports of the journal
       |  cueverge site build [--out <dir>] | cueverge site serve
       |  cueverge upgrade <version>                    move the project to another version of the tool
       |  cueverge capture web <name> <url>             capture a web page into gen/web
       |  cueverge capture project <project-dir> <name> capture the exports of a project into gen/
       |  cueverge capture check                        every capture extracts again to the same bytes
       |  cueverge runs <name> <runs-dir>...            import runs of the Go kernel into gen/runs
       |  cueverge diagram [round|init]
       |  cueverge gate                                 the rule gate (issue #3), not built yet""".stripMargin

    // @what: the options of a round, after the subcommand.
    def roundOptions(args: List[String], o: Options): Either[String, Options] = args match
        case "-j" :: n :: rest       => roundOptions(rest, o.copy(jobs = n.toInt))
        case "-show" :: n :: rest    => roundOptions(rest, o.copy(show = n.toInt))
        case "-filter" :: t :: rest  => roundOptions(rest, o.copy(filter = t))
        case "-verdict" :: v :: rest => roundOptions(rest, o.copy(only = v))
        case dir :: Nil              => Right(o.copy(dir = JPath.of(dir).normalize.toString))
        case _                       => Left(Usage)

    def initOptions(args: List[String], o: Options): Either[String, Options] = args match
        case "-problem" :: t :: rest      => initOptions(rest, o.copy(problem = t))
        case "-problem-file" :: f :: rest => initOptions(rest, o.copy(problem = Files.readString(JPath.of(f))))
        case "-replay" :: e :: rest       => initOptions(rest, o.copy(replay = e))
        case "-module" :: m :: rest       => initOptions(rest, o.copy(module = m))
        case dir :: Nil                   => Right(o.copy(dir = JPath.of(dir).normalize.toString))
        case Nil                          => Right(o.copy(dir = "."))
        case _                            => Left(Usage)

    def parse(args: List[String], o: Options = Options()): Either[String, Options] =
        def dir(d: String) = JPath.of(d).normalize.toString
        args match
            case "round" :: rest                    => roundOptions(rest, o.copy(command = "round"))
            case "agent" :: d :: Nil                => Right(o.copy(command = "agent", agent = true, dir = dir(d)))
            case "replay" :: e :: d :: Nil          => Right(o.copy(command = "replay", replay = e, dir = dir(d)))
            case "export" :: d :: Nil               => Right(o.copy(command = "export", exportOnly = true, dir = dir(d)))
            case "init" :: rest                     => initOptions(rest, o.copy(command = "init"))
            case "approve" :: h :: Nil              => Right(o.copy(command = "approve", hash = h, dir = "."))
            case "approve" :: h :: d :: Nil         => Right(o.copy(command = "approve", hash = h, dir = dir(d)))
            case "site" :: rest if rest.nonEmpty    => Right(o.copy(command = "site", rest = rest))
            case "upgrade" :: v :: Nil              => Right(o.copy(command = "upgrade", version = v))
            case "capture" :: "web" :: n :: u :: Nil => Right(o.copy(command = "capture", capture = List(Project.root(".").toString, n, u)))
            case "capture" :: "project" :: p :: n :: Nil => Right(o.copy(command = "capture-project", rest = List(p, n)))
            case "capture" :: "check" :: Nil        => Right(o.copy(command = "capture-check", captureCheck = true, dir = Project.root(".").toString))
            case "runs" :: n :: sources if sources.nonEmpty => Right(o.copy(command = "runs", runs = Project.root(".").toString :: n :: sources))
            case "diagram" :: Nil                   => Right(o.copy(command = "diagram", diagram = true))
            case "diagram" :: f :: Nil              => Right(o.copy(command = "diagram", diagram = true, rest = List(f)))
            case "gate" :: _                        => Right(o.copy(command = "gate"))
            case ("-h" | "--help" | "help") :: _    => Left(Usage)
            case _                                  => Left(Usage)

    def exit(code: Int)(using Frame): Unit < Sync = Sync.defer(java.lang.System.exit(code))

    run {
        Abort.recover[String](msg => Console.printLineErr(msg).andThen(exit(2))) {
            Abort.get(parse(args.toList)).map { o =>
                o.command match {
                case "diagram" =>
                    val flow = if o.rest == List("init") then Init.flow(o) else round(o)
                    Console.printLine(Flow.render(flow, Flow.DiagramFormat.Mermaid))
                        .andThen(Kyo.foreachDiscard(Flow.lint(flow))(w => Console.printLineErr(s"lint: $w")))
                case "replay"          => replay(o)
                case "agent"           => Agent.run(o)
                case "export"          => Export.all(o)
                case "init"            => Init.run(o)
                case "approve"         => Init.approve(o)
                case "site"            => Project.site(o.rest)
                case "upgrade"         => Project.upgrade(o.version)
                case "capture"         => WebCapture.capture(o.capture(0), o.capture(1), o.capture(2))
                case "capture-project" => ProjectCapture.capture(o.rest(0), o.rest(1))
                case "capture-check"   => WebCapture.check(o.dir).andThen(RunCapture.check(o.dir)).andThen(ProjectCapture.check(o.dir))
                case "runs"            => RunCapture.capture(o.runs(0), o.runs(1), o.runs.drop(2))
                case "gate"            => Abort.fail("cueverge gate: the rule gate is not built yet (issue #3)")
                case _                 => roundCommand(o)
                }
            }
        }
    }

    // @what: cueverge round <initiative-dir>: one round, reported.
    def roundCommand(o: Options)(using Frame): Unit < (Async & Abort[String]) =
        if !Files.exists(JPath.of(o.dir, "initiative.cue")) then
            // @invariant: never write a seal where there is no initiative, since it would move a fixed point.
            Abort.fail(s"${o.dir}: not an initiative (no initiative.cue)")
        else
            Sync.defer(Files.createDirectories(JPath.of(".cache", "oracle"))).andThen {
                Sync.defer(Files.exists(JPath.of(o.dir, sealedFile))).map { exists =>
                    if exists then Kyo.unit else Tools.set(o.dir, sealedFile, pkg, "sealed", ujson.Obj())
                }
            }.andThen(Clock.stopwatch).map { watch =>
                execute(o, Absent).map { r =>
                    watch.elapsed.map(took => report(r, took, o)).andThen(finish(r))
                }
            }

    // --- The engine ------------------------------------------------------------


    // @what: the raw journal and the exports of an initiative, in the gen module of its knowledge base.
    // @what: set inside the sandbox of a generation, to its scratch folder. A round there keeps nothing in the base.
    val SandboxEnv = "CUEVERGE_SANDBOX"
    // @what: the build tag of the journal rule. The rule needs the raw journal, so it applies when an export is written.
    val JournalTag = "journalraw"
    def sandbox: Option[String] = Option(java.lang.System.getenv(SandboxEnv)).filter(_.nonEmpty)
    def journalDir(dir: String): String =
        sandbox.fold(Tools.module(dir)._1.resolve("gen/journal"))(s => JPath.of(s, "journal")).resolve(JPath.of(dir).getFileName).toString
    def journalDir(o: Options): String = journalDir(o.dir)
    // @what: the rule that checks the exports of an initiative against its raw journal, in the cogen module.
    def journalRulesDir(o: Options): String = Tools.module(o.dir)._1.resolve("cogen/journal").resolve(JPath.of(o.dir).getFileName).toString

    // @what: runs one execution of flow over a CueFlowStore, then reads what it recorded. With seeds it starts with those fields, a replay.
    def runFlow[A](o: Options, flow: Flow[?, ?, ?], name: String, seeds: Maybe[(String, Dict[String, FlowStore.FieldData])])(
        read: (FlowStore, Flow.Id.Execution) => A < (Async & Abort[FlowException | FlowStoreException | String])
    )(using Frame): A < (Async & Abort[String]) =
        runFlowIn(journalDir(o), journalRulesDir(o), flow, name, seeds, done)(read)

    // @what: the execution is over. A round or a generation waits for nothing.
    def done(fields: Set[String], status: Flow.Status): Boolean = status == Flow.Status.Completed

    // @what: runs one execution of flow over a CueFlowStore in journal, until stop holds, then reads it and writes its exports.
    def runFlowIn[A](journal: String, rules: String, flow: Flow[?, ?, ?], name: String, seeds: Maybe[(String, Dict[String, FlowStore.FieldData])],
        stop: (Set[String], Flow.Status) => Boolean)(
        read: (FlowStore, Flow.Id.Execution) => A < (Async & Abort[FlowException | FlowStoreException | String])
    )(using Frame): A < (Async & Abort[String]) =
        val wf = Flow.Id.Workflow(name)
        Abort.recover[FlowException | FlowStoreException](e => Abort.fail(s"flow: ${e.getMessage}")) {
            Scope.run {
                for
                    store  <- CueFlowStore.init(journal)
                    engine <- FlowEngine.init(store, FlowEngine.Config(workerCount = 1, pollTimeout = 100.millis), flow)
                    eid <- seeds match
                        case Absent => engine.workflows.start(wf).map(_.executionId)
                        case Present((id, fields)) =>
                            for
                                info <- store.getWorkflow(wf)
                                now  <- Clock.now
                                eid = Flow.Id.Execution(id)
                                _ <- store.createExecutionIfAbsent(eid, Flow.Status.Running, Flow.Event.Created(wf, eid, now),
                                    info.map(_.structuralHash).getOrElse(""), fields)
                            yield eid
                    _ <- await(store, eid, stop)
                    a <- read(store, eid)
                yield (eid, a)
            }.map { (eid, a) =>
                // @what: The raw journal is Kyo's. What we keep is its export, checked against it.
                // @why: a round inside a generation sandbox keeps nothing, so it writes no export into the base.
                if sandbox.nonEmpty then a else Export.of(journal, rules).andThen(a)
            }
        }
    end runFlowIn

    // @what: Runs the round, or replays it from seeds.
    def execute(o: Options, seeds: Maybe[(String, Dict[String, FlowStore.FieldData])])(using Frame): Recorded < (Async & Abort[String]) =
        // @what: A round in progress is over, even one that failed. Without observations, the knowledge base vets.
        val empty = Sync.defer(Files.writeString(JPath.of(o.dir, observedFile),
            s"// Generated by the kernel. Do not edit.\npackage $pkg\n\nobserved: {}\n"): Unit)
        if seeds.isEmpty then Sync.ensure(empty)(runRound(o, seeds)) else runRound(o, seeds)

    def runRound(o: Options, seeds: Maybe[(String, Dict[String, FlowStore.FieldData])])(using Frame): Recorded < (Async & Abort[String]) =
        runFlow(o, round(o), "round", seeds) { (store, eid) =>
            for
                in  <- store.getField[Initiative](eid, "initiative").map(need(_, "initiative"))
                obs <- store.getField[Chunk[Seen]](eid, "observe").map(need(_, "observe"))
                ret <- store.getField[Judgment](eid, "retime").map(need(_, "retime"))
                dec <- store.getField[Decision](eid, "decision").map(need(_, "decision"))
                int <- store.getField[IntentView](eid, "intent")
            yield Recorded(eid.value, in, obs, ret, dec, int)
        }

    def need[A](m: Maybe[A], what: String)(using Frame): A < Abort[String] =
        m match
            case Present(a) => a
            case Absent     => Abort.fail(s"nothing recorded for $what")

    def await(store: FlowStore, eid: Flow.Id.Execution, stop: (Set[String], Flow.Status) => Boolean)(using
        Frame
    ): Unit < (Async & Abort[FlowException | FlowStoreException | String]) =
        Async.sleep(20.millis).andThen(store.getExecution(eid)).map {
            case Present(s) =>
                s.status match
                    case Flow.Status.Failed(err, _) => Abort.fail(s"execution ${eid.value} failed: $err")
                    case Flow.Status.Cancelled      => Abort.fail(s"execution ${eid.value} was cancelled")
                    case status =>
                        store.getAllFields(eid).map { fields =>
                            if stop(fields.toMap.keySet, status) then Kyo.unit else await(store, eid, stop)
                        }
            case Absent => await(store, eid, stop)
        }

    // @what: Seeds a new execution with what `id` recorded before `decision`, decides again, and compares.
    def replay(o: Options)(using Frame): Unit < (Async & Abort[String]) =
        val files = Seq(observedFile, sealedFile).map(f => JPath.of(o.dir, f))
        for
            recorded <- CueFlowStore.fields(journalDir(o), o.replay)
            before    = recorded.filter((name, _) => !name.startsWith("decision"))
            fd       <- need(recorded.get("decision"), s"the decision of ${o.replay}")
            original <- Abort.get(Json.decode[Decision](fd.value).mapFailure(e => s"cannot read the decision of ${o.replay}: $e"))
            saved <- Sync.defer(files.map(f => f -> Files.readString(f)))
            stamp <- Clock.now.map(_.toJava.toEpochMilli)
            again <- Sync.ensure(Sync.defer(saved.foreach((f, text) => Files.writeString(f, text): Unit))) {
                execute(o, Present((s"${o.replay}-replay-$stamp", before)))
            }
            _ <- Console.printLine(s"replay of ${o.replay} as ${again.execution}: seeded ${before.size} fields, decided again")
            _ <-
                if again.decision == original then Console.printLine(s"DETERMINISTIC: same decision (holds = ${original.holds})")
                else
                    Console.printLine(s"DIFFERENT DECISION\n  recorded: $original\n  replayed: ${again.decision}").andThen(exit(1))
        yield ()

    // @what: What the runner says of the intent. The status comes from CUE.
    def intentLines(i: IntentView): Seq[String] =
        val head = s"intent ${i.hash}: ${i.status}" + (if i.approvedBy != "none" then s", approved by ${i.approvedBy}" else "") +
            (if i.goal.nonEmpty then s" — ${i.goal}" else "")
        head +: (i.notFixed.map(c => s"  CLAIMED, NOT FIXED $c") ++ i.unannounced.map(c => s"  UNANNOUNCED REGRESSION $c") ++
            i.excused.map(c => s"  EXCUSED by a person $c"))

    def finish(r: Recorded)(using Frame): Unit < (Sync & Async) =
        val (j, d) = (r.retime, r.decision)
        val intent = r.intent.filter(_.status != "none").map(i => Console.printLine(intentLines(i).mkString("\n", "\n", ""))).getOrElse(Kyo.unit)
        if !d.decided then intent
        else if d.holds then
            val excused = r.intent.map(_.excused).getOrElse(Nil)
            val what = if excused.isEmpty then "no regression" else s"${excused.size} regression(s) excused by a person, no other"
            intent.andThen(Console.printLine(s"\nSEALED: $what, the verdicts of this round are the new reference"))
        else
            val r = j.summary.regressed
            intent.andThen(Console.printLine(s"\nREFUSED: the round does not meet the rules and the seal (${r.size} regression(s))"))
                .andThen(Kyo.foreachDiscard(r)(c => Console.printLine(s"  REGRESSION $c (${j.verdicts.getOrElse(c, "no verdict")})")))
                .andThen(Console.printLine(s"\ncue vet -c:\n${clip(d.report, 1200)}"))
                .andThen(exit(1))

    def report(r: Recorded, took: Duration, o: Options)(using Frame): Unit < Sync =
        val (name, j) = (r.initiative.name, r.retime)
        val byPath    = r.observe.map(x => x.path -> x).toMap
        val counts = j.summary.count.collect { case c if c.n > 0 => f"  ${c.verdict}%-15s ${c.n}%4d" }
        val (valid, good) = (j.summary.valid, j.summary.validCorrect)
        val shown = j.summary.failing.filter(c => o.only.isEmpty || j.verdicts(c) == o.only).take(o.show).map { c =>
            val x = byPath(c)
            def indent(s: String) = s.replace("\n", "\n             ")
            s"\n[${j.verdicts(c)}] $c\n  oracle:    ${indent(x.oracleText)}\n  candidate: ${indent(x.candidateText)}"
        }
        val lines = Seq(s"$name: ${j.summary.cases} cases in ${took.toMillis} ms (execution ${r.execution})") ++ counts ++
            (if valid > 0 then Seq("valid inputs answered correctly: %d/%d (%.1f%%)".formatLocal(java.util.Locale.ROOT, good, valid, 100.0 * good / valid))
             else Nil) ++ shown
        Console.printLine(lines.mkString("\n"))

    def clip(s: String, n: Int): String =
        val t = s.trim
        if t.length > n then t.take(n) + "…" else t

    // @what: The glob of an initiative. A directory part and a pattern on file names.
    def glob(pattern: String): Seq[String] =
        val matcher = java.nio.file.FileSystems.getDefault.getPathMatcher(s"glob:$pattern")
        val prefix  = pattern.takeWhile(ch => ch != '*' && ch != '?' && ch != '[').reverse.dropWhile(_ != '/').reverse
        val stream  = Files.walk(JPath.of(if prefix.isEmpty then "." else prefix))
        try stream.iterator.asScala.map(_.toString).filter(p => matcher.matches(JPath.of(p))).toSeq.sorted
        finally stream.close()
end Main
