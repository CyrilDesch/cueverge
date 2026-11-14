// @what: the effect of the kernel. Start a command on a case, wait for it, time it.
// @invariant: it knows nothing about what the answer means.

package kernel

import kyo.*

import java.nio.charset.StandardCharsets.UTF_8
import java.nio.file.{Files, Path as JPath}
import java.security.MessageDigest

// @what: #Command in the factory rules. `{case}` is replaced by the case path.
// @ref: @/tool/cue/rules/schema.rules.cue
final case class Cmd(cmd: Seq[String], timeoutMs: Int)

// @what: What one command said about one case, in full.
final case class Answer(exit: Int, out: String, err: String, timeout: Boolean, ms: Int)

object Run:

    private def utf8(bytes: Chunk[Byte]): String = String(bytes.toArray, UTF_8)

    // @what: runs c on one case and times it. A command that cannot start exits 127.
    // @what: `unset` names the environment variables the command must not inherit.
    def run(c: Cmd, casePath: String, unset: Seq[String] = Nil, cwd: Maybe[JPath] = Absent, env: Map[String, String] = Map.empty)(using
        Frame
    ): Answer < Async =
        val args  = c.cmd.map(_.replace("{case}", casePath))
        val limit = (if c.timeoutMs > 0 then c.timeoutMs else 10000).millis
        Clock.stopwatch.map { watch =>
            val attempt: Answer < (Async & Abort[CommandException | Timeout]) =
                Async.timeout(limit) {
                    Scope.run {
                        val base = Command(args*).envRemove(unset).envAppend(env)
                        cwd.fold(base)(d => base.cwd(kyo.Path(d.toString))).spawn.map { p =>
                            p.collectOutput.map { (out, err) =>
                                p.waitFor.map { code =>
                                    watch.elapsed.map(d => Answer(code.toInt, utf8(out), utf8(err), false, d.toMillis.toInt))
                                }
                            }
                        }
                    }
                }
            Abort.recover[Timeout](_ => watch.elapsed.map(d => Answer(-1, "", "", true, d.toMillis.toInt))) {
                Abort.recover[CommandException](e => Answer(127, "", e.getMessage, false, 0))(attempt)
            }
        }

    // @what: Runs c once per (command, case content). For the oracle only. It is pinned and deterministic.
    def cached(c: Cmd, casePath: String, cacheDir: String)(using Frame): Answer < Async =
        Sync.defer {
            val sha = MessageDigest.getInstance("SHA-256")
            sha.update(c.cmd.mkString("\u0000").getBytes(UTF_8))
            sha.update(Array[Byte](0))
            sha.update(Files.readAllBytes(JPath.of(casePath)))
            JPath.of(cacheDir, sha.digest().map("%02x".format(_)).mkString + ".json")
        }.map { file =>
            Sync.defer(if Files.exists(file) then Some(decode(Files.readString(file))) else None).map {
                case Some(a) => a
                case None =>
                    // @why: inside a generation sandbox the cache is read only. A generator must never write a reference answer.
                    run(c, casePath).map(a => Sync.defer { if Main.sandbox.isEmpty then Files.writeString(file, encode(a)): Unit; a })
            }
        }

    // @what: The cache keeps the format the Go kernel wrote, so earlier entries stay valid.
    private def encode(a: Answer): String =
        val o = ujson.Obj("exit" -> a.exit, "out" -> a.out, "err" -> a.err)
        if a.timeout then o("timeout") = true
        if a.ms > 0 then o("ms") = a.ms
        o.render()

    private def decode(s: String): Answer =
        val o = ujson.read(s).obj
        Answer(
            o.get("exit").map(_.num.toInt).getOrElse(0),
            o.get("out").map(_.str).getOrElse(""),
            o.get("err").map(_.str).getOrElse(""),
            o.get("timeout").exists(_.bool),
            o.get("ms").map(_.num.toInt).getOrElse(0)
        )
end Run
