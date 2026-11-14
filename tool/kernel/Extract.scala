// @what: the extractor. From a full answer to what can be observed of it, the #Answer of the factory rules.
// @why: forgetful on purpose. A value is kept as two hashes, of its text and of the value.
// @invariant: a fixed point. A coarser extractor loosens the rules without touching them.

package kernel

import java.nio.charset.StandardCharsets.UTF_8
import java.security.MessageDigest
import scala.util.Try

// @what: #Answer in the factory rules.
// @ref: @/tool/cue/rules/schema.rules.cue
final case class Observation(exit: Int, timeout: Boolean, text: String, value: String, err: String, ms: Seq[Int]):
    def toJson: ujson.Obj =
        val o = ujson.Obj("exit" -> exit, "timeout" -> timeout, "err" -> err, "ms" -> ujson.Arr.from(ms.map(ujson.Num(_))))
        if text.nonEmpty then o("text") = text
        if value.nonEmpty then o("value") = value
        o

// @what: One entry of #Observed.
final case class Pair(oracle: Observation, candidate: Observation):
    def toJson: ujson.Obj = ujson.Obj("oracle" -> oracle.toJson, "candidate" -> candidate.toJson)

object Extract:

    private def hash(s: String): String =
        MessageDigest.getInstance("SHA-256").digest(s.getBytes(UTF_8)).take(12).map("%02x".format(_)).mkString

    // @what: Keys sorted at every level. The value without its field order.
    private def canonical(v: ujson.Value): ujson.Value = v match
        case o: ujson.Obj => ujson.Obj.from(o.value.toSeq.sortBy(_._1).map((k, x) => k -> canonical(x)))
        case a: ujson.Arr => ujson.Arr.from(a.value.map(canonical))
        case x            => x

    // @what: `timed` keeps the time. Only for the candidate, since the oracle comes from a cache and its time means nothing.
    def apply(a: Answer, timed: Boolean): Observation =
        val (text, value) =
            if a.exit != 0 then ("", "")
            else
                Try(ujson.read(a.out)).toOption match
                    case Some(v) => (hash(v.render()), hash(canonical(v).render()))
                    case None    => ("", "")
        Observation(a.exit, a.timeout, text, value, a.err, if timed then Seq(a.ms) else Seq.empty)
end Extract
