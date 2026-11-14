// @what: the generation side of co-generation. Claude Code, run headless in the sandbox runtime, edits the candidate between rounds.
// @invariant: a refused round restores the candidate the last sealed round judged. A regression is never kept.
// @ref: @/tool/kernel/README.md

package kernel

import kyo.*

import java.nio.file.{Files, Path as JPath}
import java.security.MessageDigest
import scala.jdk.CollectionConverters.*

// @what: #Generator in the factory rules.
// @ref: @/tool/cue/rules/schema.rules.cue
final case class Generator(model: String, maxBudgetUsd: Double, maxRounds: Int, source: String, allow: Seq[String], instructions: String,
    intentAsk: String, sandbox: Sandbox)

// @what: the walls of a generation, as the initiative declares them. The rules check them, the sandbox runtime enforces them.
final case class Sandbox(write: Seq[String], files: Seq[String], domains: Seq[String])

// @what: What one `claude -p` run did.
final case class Generation(
    model: String,
    isError: Boolean,
    outcome: String,
    result: String,
    costUsd: Double,
    turns: Int,
    session: String,
    denied: Seq[String],
    seconds: Int,
    // @what: the journal file of the live trace, `claude-<session>.gen.cue`.
    trace: String
)

object Agent:

    def readGenerator(dir: String)(using Frame): Generator < (Async & Abort[String]) =
        Tools.read(dir, "initiative.generator").map { g =>
            Generator(g("model").str, g("maxBudgetUsd").num, g("maxRounds").num.toInt, g("source").str,
                g("allow").arr.toSeq.map(_.str), g("instructions").str, g("intent")("ask").str,
                Sandbox(g("sandbox")("write").arr.toSeq.map(_.str), g("sandbox")("files").arr.toSeq.map(_.str),
                    g("sandbox")("domains").arr.toSeq.map(_.str)))
        }

    // @what: one generation, as a Flow. Every node is recorded in the journal.
    def generate(o: Options, g: Generator, brief: String)(using Frame) =
        Flow.init("generate", description = "Claude Code edits the candidate, within the frame of the initiative.")
            .output("brief", description = "what Claude is told: the instructions and the cases that fail")(_ => brief)
            .output("fixedBefore", description = "hash of every fixed point before the generation")(_ => Sync.defer(fixedPoints(o.dir, g.source)))
            .output("sourceBefore", description = "the candidate before the generation")(_ => Sync.defer(Files.readString(JPath.of(g.source))))
            .output("claude", description = "claude -p, headless, as Claude Code runs; live trace in the journal") { ctx =>
                claude(g, ctx.brief, Main.journalDir(o))
            }
            .output("patch", description = "what Claude changed in the candidate") { ctx => diff(ctx.sourceBefore, g.source) }
            .output("fixedAfter", description = "hash of every fixed point after the generation")(_ => Sync.defer(fixedPoints(o.dir, g.source)))

    final case class Generated(execution: String, claude: Generation, patch: String, fixedMoved: Boolean)

    def runGenerate(o: Options, g: Generator, brief: String)(using Frame): Generated < (Async & Abort[String]) =
        Main.runFlow(o, generate(o, g, brief), "generate", Absent) { (store, eid) =>
            for
                c  <- store.getField[Generation](eid, "claude").map(Main.need(_, "claude"))
                p  <- store.getField[String](eid, "patch").map(Main.need(_, "patch"))
                fb <- store.getField[String](eid, "fixedBefore").map(Main.need(_, "fixedBefore"))
                fa <- store.getField[String](eid, "fixedAfter").map(Main.need(_, "fixedAfter"))
            yield Generated(eid.value, c, p, fb != fa)
        }

    // @what: claude -p with the model, the budget and the permissions of the initiative, and nothing else.
    // @what: the output is streamed into the journal as it arrives, and a one-line summary goes to the console.
    def claude(g: Generator, brief: String, journal: String)(using Frame): Generation < Async =
        val source = JPath.of(g.source).toAbsolutePath.toString
        // @why: an absolute rule, since Claude Code edits the file by its absolute path.
        headless(g.model, g.maxBudgetUsd, s"Edit(/$source)" +: g.allow, g.sandbox, brief, journal)

    // @what: claude -p, headless, in the sandbox runtime, with exactly these permissions. The trace lands in the journal as it streams.
    def headless(model: String, budgetUsd: Double, allowed: Seq[String], walls: Sandbox, brief: String, journal: String)(using
        Frame
    ): Generation < Async =
        val args = Seq("claude", "-p", brief, "--model", model, "--output-format", "stream-json", "--verbose",
            "--max-budget-usd", budgetUsd.toString, "--no-session-persistence",
            "--permission-mode", "default", "--allowedTools") ++ allowed
        // @what: Not a child of the session that runs the kernel.
        val unset = java.lang.System.getenv().keySet.asScala.toSeq.filter(_.startsWith("CLAUDE"))
        val (wrapped, env) = sandboxed(walls, args)
        val trace = Trace(journal)
        Clock.stopwatch.map { watch =>
            val attempt: Generation < (Async & Abort[CommandException | Timeout]) =
                Async.timeout(30.minutes) {
                    Scope.run {
                        Command(wrapped*).envRemove(unset).envAppend(env).redirectErrorStream(true).spawn.map { p =>
                            p.stdout.foreachChunk(ch => Sync.defer(trace.feed(ch.toArray))).andThen(p.waitFor).map { code =>
                                watch.elapsed.map(d => trace.generation(model, code.toInt, (d.toMillis / 1000).toInt))
                            }
                        }
                    }
                }
            Abort.recover[Timeout](_ => Generation(model, true, "timeout", "", 0, 0, trace.session, Nil, 1800, trace.name)) {
                Abort.recover[CommandException](e => Generation(model, true, "cannot start", e.getMessage, 0, 0, "", Nil, 0, "")) {
                    attempt
                }
            }
        }

    def diff(before: String, source: String)(using Frame): String < Async =
        Sync.defer {
            val tmp = Files.createTempFile("candidate-", ".py")
            Files.writeString(tmp, before): Unit
            tmp
        }.map { tmp =>
            Run.run(Cmd(Seq("diff", "-u", "--label", "before", "--label", "after", tmp.toString, source), 60000), "")
                .map(a => Sync.defer { Files.delete(tmp); a.out })
        }

    // @what: wraps claude -p in the sandbox runtime. It writes only the folders of the initiative and a scratch folder.
    // @invariant: no fallback. Without the sandbox runtime the command cannot start, and no generation runs.
    // @why: the generator runs code it wrote. Permission rules do not bind that code, the operating system does.
    def sandboxed(walls: Sandbox, args: Seq[String]): (Seq[String], Map[String, String]) =
        val scratch  = Files.createTempDirectory(JPath.of("/tmp"), "cueverge-agent-").toRealPath()
        val abs      = (p: String) => JPath.of(p).toAbsolutePath.normalize.toString
        val settings = Files.createTempFile("cueverge-sandbox-", ".json")
        Files.writeString(settings, ujson.write(ujson.Obj(
            "network" -> ujson.Obj("allowedDomains" -> ujson.Arr.from(walls.domains.map(ujson.Str(_))), "deniedDomains" -> ujson.Arr()),
            "filesystem" -> ujson.Obj(
                "denyRead" -> ujson.Arr("~/.ssh"),
                "allowWrite" -> ujson.Arr.from((walls.write ++ walls.files).map(abs).map(ujson.Str(_)) :+ ujson.Str(scratch.toString)),
                "denyWrite" -> ujson.Arr()
            )
        ), indent = 1)): Unit
        (Seq("mise", "exec", "--", "srt", "--settings", settings.toString, "--") ++ args,
            Map("TMPDIR" -> scratch.toString, "CLAUDE_CODE_TMPDIR" -> scratch.toString, Main.SandboxEnv -> scratch.toString,
                // @why: the JVM ignores TMPDIR on macOS. A kernel run by the generator takes its temporary files in the scratch folder too.
                "JAVA_TOOL_OPTIONS" -> s"-Djava.io.tmpdir=$scratch"))

    // @what: one hash over every file the generator must not touch.
    def fixedPoints(dir: String, source: String): String =
        // @what: the pinned tool (cue.mod and mise.toml), the rules of the project, the initiative and its corpus.
        // @what: never the candidate, the journal, a round in progress or the seal.
        // @ref: @/mise.toml
        val root  = Tools.module(dir)._1
        val roots = Seq(root.resolve("cue.mod"), Project.repo(root).resolve("mise.toml"), root.resolve("cogen"), JPath.of(dir))
        val skip  = Seq(JPath.of(source), JPath.of(Main.journalDir(dir)), JPath.of(dir, "observed.gen.cue"), JPath.of(dir, "sealed.gen.cue"),
            root.resolve("cue.mod/registry"), root.resolve(".cache")).map(_.toAbsolutePath.normalize)
        val files = roots.map(_.toAbsolutePath.normalize).filter(Files.exists(_)).flatMap { r =>
            val s = Files.walk(r)
            try s.iterator.asScala.filter(Files.isRegularFile(_)).toSeq finally s.close()
        }.filterNot(f => skip.exists(f.startsWith) || f.toString.contains("/runs")).map(_.toString).distinct.sorted
        val sha = MessageDigest.getInstance("SHA-256")
        files.foreach { f =>
            sha.update(f.getBytes("UTF-8"))
            sha.update(Files.readAllBytes(JPath.of(f)))
        }
        sha.digest().map("%02x".format(_)).mkString

    // @what: the intent in the last message of Claude, the last `intent` block, as #Intent. Only goal, fixes and regressions, as strings.
    // @invariant: no block, or a broken one, gives an empty claim, which CUE calls malformed. The extractor is part of the trusted frame.
    def intentOf(result: String): ujson.Value =
        val block = "(?s)```intent\\s*\\n(.*?)```".r.findAllMatchIn(result).toSeq.lastOption.map(_.group(1))
        val parsed = block.flatMap(b => scala.util.Try(ujson.read(b)).toOption).collect { case o: ujson.Obj => o }
        def str(v: ujson.Value) = v match
            case ujson.Str(x) => Some(x)
            case _            => None
        val goal  = parsed.flatMap(_.value.get("goal")).flatMap(str).getOrElse("")
        val fixes = parsed.flatMap(_.value.get("fixes")).collect { case a: ujson.Arr => a.value.toSeq.flatMap(str) }.getOrElse(Nil)
        val regressions = parsed.flatMap(_.value.get("regressions")).collect { case o: ujson.Obj =>
            o.value.toSeq.flatMap((k, v) => str(v).map(k -> _)) }.getOrElse(Nil)
        ujson.Obj("declared" -> true, "goal" -> goal, "fixes" -> ujson.Arr.from(fixes.distinct.sorted.map(ujson.Str(_))),
            "regressions" -> ujson.Obj.from(regressions.sortBy(_._1).map((k, v) => k -> ujson.Str(v))))

    // @what: what Claude is told. The frame of the initiative, then what failed in the last round.
    def brief(g: Generator, r: Recorded, refused: Maybe[Recorded]): String =
        val j      = r.retime
        val byPath = r.observe.map(x => x.path -> x).toMap
        val cases = j.summary.failing.take(15).map { c =>
            val x = byPath(c)
            s"[${j.verdicts(c)}] $c\n  reference: ${x.oracleText.replace("\n", "\n             ")}\n  candidate: ${x.candidateText.replace("\n", "\n             ")}"
        }
        val refusal = refused match
            case Present(bad) =>
                s"\nYour previous change was REFUSED and undone: it broke cases that passed (${bad.retime.summary.regressed.mkString(", ")}).\n"
            case Absent => ""
        s"""${g.instructions}
           |$refusal
           |The last sealed round: ${j.summary.validCorrect}/${j.summary.valid} valid inputs answered correctly, ${j.summary.failing.size} cases fail.
           |The first ones:
           |
           |${cases.mkString("\n\n")}
           |
           |${g.intentAsk}
           |""".stripMargin

    // --- The loop ------------------------------------------------------------

    def run(o: Options)(using Frame): Unit < (Async & Abort[String]) =
        readGenerator(o.dir).map { g =>
            Console.printLine(s"agent: ${g.model}, up to ${g.maxRounds} generations, ${g.maxBudgetUsd} USD each, edits ${g.source}").andThen {
                round(o, g, 0, 0.0, Absent, Absent)
            }
        }

    // @what: `kept` is the last round that held and the candidate it judged, `refused` the last round that did not.
    def round(o: Options, g: Generator, done: Int, spent: Double, kept: Maybe[(Recorded, String)], refused: Maybe[Recorded])(
        using Frame
    ): Unit < (Async & Abort[String]) =
        Main.execute(o, Absent).map { r =>
            val s = r.retime.summary
            val line = s"round ${r.execution}: ${s.validCorrect}/${s.valid} valid correct, ${if r.decision.holds then "SEALED" else s"REFUSED (${s.regressed.size} regression(s))"}"
            val awaiting = r.intent.filter(_.status == "awaiting")
            Console.printLine(line).andThen(Kyo.foreachDiscard(r.intent.filter(_.status != "none").toList.flatMap(Main.intentLines))(l => Console.printLine(s"  $l"))).andThen {
              if awaiting.nonEmpty then
                val i = awaiting.get
                Console.printLine(
                    s"""stop: the intent ${i.hash} awaits a person. The candidate is kept as it is.
                       |  read: ${o.dir}/${Main.intentFile}
                       |  approve: cueverge approve ${i.hash} ${o.dir}
                       |  then: cueverge round ${o.dir}
                       |Spent ${f"$spent%.2f"} USD.""".stripMargin)
              else
                Sync.defer(Files.readString(JPath.of(g.source))).map { now =>
                    // @what: A refused round leaves the candidate as the last sealed round judged it.
                    val (base, lastRefused) =
                        if r.decision.holds then ((r, now), Absent)
                        else kept match
                            case Present((sr, text)) => ((sr, text), Present(r))
                            case Absent              => ((r, now), Present(r))
                    val restore =
                        if r.decision.holds then Kyo.unit
                        else Sync.defer(Files.writeString(JPath.of(g.source), base._2): Unit)
                            // @what: The claim was about the change just undone.
                            .andThen(Tools.set(o.dir, Main.intentFile, Main.pkg, "intent", ujson.Obj()))
                            .andThen(Console.printLine("  the candidate is restored to the last sealed version"))
                    restore.andThen {
                        val (best, _) = base
                        if best.retime.summary.validCorrect == best.retime.summary.valid then
                            Console.printLine(s"stop: every valid input is answered correctly. Spent ${f"$spent%.2f"} USD.")
                        else if done == g.maxRounds then
                            Console.printLine(s"stop: ${g.maxRounds} generations ran. Spent ${f"$spent%.2f"} USD.")
                        else
                            runGenerate(o, g, brief(g, best, lastRefused)).map { gen =>
                                val c = gen.claude
                                Console.printLine(
                                    s"generate ${gen.execution}: ${c.outcome}, ${c.turns} turns, ${f"${c.costUsd}%.2f"} USD, ${c.seconds} s, " +
                                        s"${gen.patch.linesIterator.count(l => l.startsWith("+") || l.startsWith("-"))} changed lines" +
                                        (if c.denied.nonEmpty then s", ${c.denied.size} permission(s) denied" else "")
                                ).andThen {
                                    if gen.fixedMoved then
                                        Console.printLine("stop: a fixed point moved during the generation. Nothing is sealed.")
                                            .andThen(Main.exit(1))
                                    else
                                        Tools.set(o.dir, Main.intentFile, Main.pkg, "intent", intentOf(c.result))
                                            .andThen(round(o, g, done + 1, spent + c.costUsd, Present(base), lastRefused))
                                }
                            }
                    }
                }
            }
        }
end Agent

// @what: the live trace of one claude -p run. Its stream-json lines go to the journal as CUE as they arrive.
final class Trace(dir: String):
    private val buf     = java.io.ByteArrayOutputStream()
    private val pending = scala.collection.mutable.ArrayBuffer.empty[String]
    private val other   = StringBuilder()
    private var n       = 0
    var session         = ""
    var result: Option[ujson.Value] = None

    def name: String = if session.isEmpty then "" else s"claude-$session.gen.cue"

    def feed(bytes: Array[Byte]): Unit =
        bytes.foreach { b =>
            if b == '\n' then
                line(buf.toString(java.nio.charset.StandardCharsets.UTF_8))
                buf.reset()
            else buf.write(b.toInt)
        }

    private def line(s: String): Unit =
        scala.util.Try(ujson.read(s)).toOption match
            case Some(j: ujson.Obj) => handle(j)
            case _ => if s.trim.nonEmpty then other.append(s).append('\n'): Unit

    private def handle(j: ujson.Obj): Unit =
        val kind = j.value.get("type").map(_.str).getOrElse("")
        if session.isEmpty then j.value.get("session_id").foreach(v => session = v.str)
        record(j.render())
        say(kind, j)
        if kind == "result" then result = Some(j)

    private def record(json: String): Unit =
        if session.isEmpty then pending += json
        else
            val f = JPath.of(dir, name)
            if !Files.exists(f) then
                Files.createDirectories(JPath.of(dir)): Unit
                Files.writeString(f, "// Generated by the kernel: the live trace of one claude -p run. Append-only.\npackage journal\n\n"): Unit
            val lines = (pending.toSeq :+ json).map { x =>
                n += 1
                s"traces: ${ujson.Str(session).render()}: \"${"%06d".format(n)}\": $x"
            }
            pending.clear()
            Files.writeString(f, lines.mkString("", "\n", "\n"), java.nio.charset.StandardCharsets.UTF_8, java.nio.file.StandardOpenOption.APPEND): Unit

    private def say(kind: String, j: ujson.Obj): Unit =
        def out(s: String) = java.lang.System.err.println(s"    claude | $s")
        def short(s: String, n: Int = 110) = { val t = s.replace("\n", " "); if t.length > n then t.take(n) + "…" else t }
        kind match
            case "system" if j.value.get("subtype").exists(_.str == "init") => out(s"session $session")
            case "assistant" =>
                j("message")("content").arr.foreach { c =>
                    c("type").str match
                        case "tool_use" => out(s"${c("name").str} ${short(c("input").render(), 100)}")
                        case "text"     => out(s"says: ${short(c("text").str)}")
                        case _          => ()
                }
            case "user" =>
                j.value.get("message").flatMap(_.obj.get("content")).filter(_.isInstanceOf[ujson.Arr]).foreach { cs =>
                    cs.arr.foreach { c =>
                        if c.obj.get("is_error").exists(_.bool) then
                            val text = c.obj.get("content").map(x => if x.isInstanceOf[ujson.Str] then x.str else x.render()).getOrElse("")
                            out(s"error: ${short(text)}")
                    }
                }
            case "result" =>
                out(s"done: ${j.value.get("subtype").map(_.str).getOrElse("")}, ${j.value.get("num_turns").map(_.num.toInt).getOrElse(0)} turns, " +
                    f"${j.value.get("total_cost_usd").map(_.num).getOrElse(0.0)}%.2f USD")
            case _ => ()

    def generation(model: String, exit: Int, seconds: Int): Generation =
        result match
            case Some(j) =>
                def str(k: String) = j.obj.get(k).filter(_.isInstanceOf[ujson.Str]).map(_.str).getOrElse("")
                val denied = j.obj.get("permission_denials").map(_.arr.toSeq.map(_.render())).getOrElse(Nil)
                Generation(model, j.obj.get("is_error").exists(_.bool), str("subtype"), str("result"),
                    j.obj.get("total_cost_usd").map(_.num).getOrElse(0.0), j.obj.get("num_turns").map(_.num.toInt).getOrElse(0),
                    session, denied, seconds, name)
            case None =>
                Generation(model, true, s"exit $exit", Main.clip(other.toString, 2000), 0, 0, session, Nil, seconds, name)
end Trace
