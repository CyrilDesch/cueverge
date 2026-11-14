// @what: captures a web page raw, and extracts its text blocks without judgement.
// @invariant: forgetful. It keeps text blocks and never decides what a block means.
// @why: part of the trusted frame, so it stays small enough to read.
// @ref: $> cueverge capture web <name> <url>
// @ref: $> cueverge capture check
package kernel

import kyo.*

import java.io.ByteArrayOutputStream
import java.net.URI
import java.net.http.{HttpClient, HttpRequest, HttpResponse}
import java.nio.charset.StandardCharsets.UTF_8
import java.nio.file.{Files, Path as JPath}
import java.security.MessageDigest
import java.util.zip.{GZIPInputStream, GZIPOutputStream}
import scala.jdk.CollectionConverters.*

object WebCapture:

    private val Dropped = "(?is)<(script|style|noscript|svg|template)\\b.*?</\\1>".r
    private val Block   = "(?is)<(p|li|h[1-6]|td|th|blockquote|figcaption)\\b[^>]*>(.*?)</\\1>".r
    private val Tag     = "(?s)<[^>]*>".r
    private val Space   = "\\s+".r
    private val Entity  = "&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z]+);".r

    private val named = Map(
        "amp" -> "&", "lt" -> "<", "gt" -> ">", "quot" -> "\"", "apos" -> "'", "nbsp" -> " ",
        "rsquo" -> "’", "lsquo" -> "‘", "rdquo" -> "”", "ldquo" -> "“", "mdash" -> "—", "ndash" -> "–",
        "hellip" -> "…", "times" -> "×", "rarr" -> "→", "larr" -> "←", "eacute" -> "é", "copy" -> "©")

    private def decode(s: String): String = Entity.replaceAllIn(s, m =>
        val e = m.group(1)
        val out =
            if e.startsWith("#x") || e.startsWith("#X") then new String(Character.toChars(Integer.parseInt(e.drop(2), 16)))
            else if e.startsWith("#") then new String(Character.toChars(e.drop(1).toInt))
            else named.getOrElse(e, m.matched)
        java.util.regex.Matcher.quoteReplacement(out))

    // @what: the blocks of a page in order, as (tag, text). Empty blocks are dropped.
    def blocks(html: String): Seq[(String, String)] =
        Block.findAllMatchIn(Dropped.replaceAllIn(html, " ")).map { m =>
            val text = Space.replaceAllIn(decode(Tag.replaceAllIn(m.group(2), " ")), " ").trim
            m.group(1).toLowerCase -> text
        }.filter(_._2.nonEmpty).toSeq

    private def sha256(b: Array[Byte]) = MessageDigest.getInstance("SHA-256").digest(b).map("%02x".format(_)).mkString

    // @invariant: the rendered page.gen.cue depends only on the raw page, the url and the fetch date.
    def render(raw: Array[Byte], url: String, fetched: String): String =
        val bs = blocks(new String(raw, UTF_8)).map((t, x) => ujson.Obj("tag" -> t, "text" -> x))
        "// @generated: the text blocks of a captured web page. Do not edit.\n// @ref: @/tool/kernel/WebCapture.scala\n// @ref: $> cueverge capture check\n" +
            "package web\n\n" +
            s"source: ${ujson.write(ujson.Obj("url" -> url, "fetched" -> fetched, "sha256" -> sha256(raw)), indent = 1)}\n\n" +
            s"blocks: ${ujson.write(ujson.Arr.from(bs), indent = 1)}\n"

    private def gzip(b: Array[Byte]): Array[Byte] =
        val out = ByteArrayOutputStream()
        val z   = GZIPOutputStream(out)
        z.write(b); z.close()
        out.toByteArray

    private def gunzip(f: JPath): Array[Byte] =
        val in = GZIPInputStream(Files.newInputStream(f))
        try in.readAllBytes() finally in.close()

    def capture(kbDir: String, name: String, url: String)(using Frame): Unit < (Async & Abort[String]) =
        Sync.defer {
            require(name.matches("[a-z0-9][a-z0-9-]*"), s"bad name: $name")
            val client = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NORMAL).build()
            val req    = HttpRequest.newBuilder(URI.create(url)).header("User-Agent", "Mozilla/5.0 (cueverge capture)").build()
            val resp   = client.send(req, HttpResponse.BodyHandlers.ofByteArray())
            if resp.statusCode != 200 then Left(s"$url: HTTP ${resp.statusCode}")
            else
                val raw     = resp.body
                val fetched = java.time.OffsetDateTime.now(java.time.ZoneOffset.UTC).withNano(0).toString
                val dir     = JPath.of(kbDir).resolve("gen/web").resolve(name)
                Files.createDirectories(dir.resolve("raw")): Unit
                Files.write(dir.resolve("raw/page.html.gz"), gzip(raw)): Unit
                Files.writeString(dir.resolve("raw/meta.json"), ujson.write(ujson.Obj("url" -> resp.uri.toString, "fetched" -> fetched), indent = 1) + "\n"): Unit
                Files.writeString(dir.resolve("page.gen.cue"), render(raw, resp.uri.toString, fetched)): Unit
                Right(s"capture: $name, ${blocks(new String(raw, UTF_8)).size} blocks from ${resp.uri}")
        }.map {
            case Right(msg) => Console.printLine(msg)
            case Left(err)  => Abort.fail(err)
        }

    // @invariant: every capture extracts again to the same bytes, so no hand edited its page.gen.cue.
    def check(kbDir: String)(using Frame): Unit < (Async & Abort[String]) =
        Sync.defer {
            val root = JPath.of(kbDir).resolve("gen/web")
            val dirs =
                if !Files.isDirectory(root) then Nil
                else
                    val s = Files.list(root)
                    try s.iterator.asScala.filter(Files.isDirectory(_)).toSeq.sorted finally s.close()
            dirs.flatMap { d =>
                val meta = ujson.read(Files.readString(d.resolve("raw/meta.json")))
                val want = render(gunzip(d.resolve("raw/page.html.gz")), meta("url").str, meta("fetched").str)
                val have = if Files.exists(d.resolve("page.gen.cue")) then Files.readString(d.resolve("page.gen.cue")) else ""
                if want == have then None else Some(s"${root.relativize(d)}: page.gen.cue differs from its raw page")
            } -> dirs.size
        }.map { (bad, n) =>
            if bad.isEmpty then Console.printLine(s"capture: $n page(s) extract again to the same bytes")
            else Abort.fail(bad.mkString("\n"))
        }
end WebCapture
