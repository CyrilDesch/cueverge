// @what: a project that imports cueverge. Its root is the nearest cue.mod. It pins the tool twice, as a CUE dependency and in mise.toml.
// @invariant: the binary and the CUE module of the tool carry one version. A project moves both with `cueverge upgrade`.
// @ref: @/mise.toml
package kernel

import kyo.*

import java.nio.file.{Files, Path as JPath}

object Project:

    // @what: the version of this binary, and of the CUE module it was released with.
    val Version = "0.1.0"
    // @what: the CUE module of the tool, as a project imports it.
    val Module = "github.com/cyrildesch/cueverge@v0"
    // @what: the mise tool that installs this binary.
    val MiseTool = "github:CyrilDesch/cueverge"
    // @what: where the CUE module of the tool is published.
    // @todo: ghcr.io once the module is published there. Until then a local OCI registry serves it.
    val Registry = "github.com/cyrildesch=localhost:5050+insecure,registry.cue.works"

    // @what: the environment of every CUE call. A project that sets CUE_REGISTRY keeps it.
    def cueEnv: Map[String, String] =
        if Option(java.lang.System.getenv("CUE_REGISTRY")).exists(_.nonEmpty) then Map.empty else Map("CUE_REGISTRY" -> Registry)

    // @what: the folder of a project that holds its CUE module, its knowledge and its journal.
    val Folder = "cueverge"

    // @what: the CUE module of the project that holds dir. From the root of a repository, its cueverge folder.
    def root(dir: String): JPath =
        val d = JPath.of(dir).toAbsolutePath.normalize
        if Files.isDirectory(d.resolve(Folder).resolve("cue.mod")) then d.resolve(Folder) else Tools.module(dir)._1

    // @what: the repository of a project. It holds mise.toml, the CI and the cueverge folder.
    // @ref: @/mise.toml
    def repo(module: JPath): JPath =
        if module.getFileName != null && module.getFileName.toString == Folder && module.getParent != null then module.getParent else module

    // @what: runs a command in cwd with the terminal of the person, and fails on a non-zero exit.
    def interactive(cwd: JPath, cmd: Seq[String])(using Frame): Unit < (Sync & Abort[String]) =
        Sync.defer {
            val pb = ProcessBuilder(cmd*).directory(cwd.toFile).inheritIO()
            cueEnv.foreach((k, v) => pb.environment.put(k, v): Unit)
            pb.start().waitFor()
        }.map(code => if code == 0 then Kyo.unit else Abort.fail(s"${cmd.mkString(" ")}: exit $code"))

    // @what: cueverge site build|serve. The project vets first, then Polaris renders its portal.
    def site(args: List[String])(using Frame): Unit < (Async & Abort[String]) =
        val r = root(".")
        args match
            case "build" :: rest =>
                val out = rest match
                    case "--out" :: d :: Nil => d
                    case Nil                 => r.resolve(".polaris/out").toString
                    case _                   => ""
                if out.isEmpty then Abort.fail(Main.Usage)
                else
                    interactive(r, Seq(Tools.Cue, "vet", "-c", "./..."))
                        .andThen(interactive(r, Seq("polaris", "site", "build", "--out", out)))
                        .andThen(Console.printLine(s"site: built in $out"))
            case "serve" :: Nil => interactive(r, Seq("polaris", "site", "serve"))
            case _              => Abort.fail(Main.Usage)

    // @what: moves the project to another version of the tool. The CUE dependency and the mise pin change together.
    def upgrade(version: String)(using Frame): Unit < (Async & Abort[String]) =
        val r = root(".")
        val v = version.stripPrefix("v")
        if !v.matches("[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?") then Abort.fail(s"upgrade: not a version: $version")
        else
            interactive(r, Seq(Tools.Cue, "mod", "get", s"${Module.stripSuffix("@v0")}@v$v")).andThen {
                Sync.defer {
                    val mise = repo(r).resolve("mise.toml")
                    val text = if Files.exists(mise) then Files.readString(mise) else ""
                    val line = s"\"$MiseTool\" = \"$v\""
                    val pin  = s"(?m)^\"${java.util.regex.Pattern.quote(MiseTool)}\" = \"[^\"]*\"$$".r
                    val next = if pin.findFirstIn(text).nonEmpty then pin.replaceAllIn(text, java.util.regex.Matcher.quoteReplacement(line))
                        else text + s"\n[tools]\n$line\n"
                    Files.writeString(mise, next): Unit
                }
            }.andThen(interactive(r, Seq(Tools.Cue, "vet", "-c", "./...")))
                .andThen(Console.printLine(s"upgrade: the project uses cueverge $v. Run `mise install` for the binary."))
end Project
