// @what: the files of a new project, as cueverge init writes them. Text only, a function of the module path, the name and the problem.
// @invariant: no clock, no randomness. The same arguments give the same bytes.
package kernel

object Templates:

    val PolarisPin = "0.0.0-b27ca809"
    val CuePin     = "0.18.0-rc.4"
    val SrtPin     = "0.0.83"

    private def str(s: String) = ujson.Str(s).render()

    def files(module: String, name: String, problem: String): Map[String, String] =
        val tool = Project.Module.stripSuffix("@v0")
        Map(
            s"${Project.Folder}/cue.mod/module.cue" ->
                s"""module: ${str(module)}
                   |language: version: "v0.18.0"
                   |deps: ${str(Project.Module)}: v: "v${Project.Version}"
                   |""".stripMargin,
            "mise.toml" ->
                s"""# @what: the tools of the project. cueverge is the factory, cue and polaris check the project and render its portal.
                   |# @invariant: the cueverge pin and the CUE dependency carry one version. cueverge upgrade moves both.
                   |[tools]
                   |"${Project.MiseTool}" = "${Project.Version}"
                   |"github:cue-lang/cue" = "$CuePin"
                   |"github:CyrilDesch/polaris" = "$PolarisPin"
                   |"npm:@anthropic-ai/sandbox-runtime" = "$SrtPin"
                   |hugo = "0.145.0"
                   |
                   |[env]
                   |# @what: where the CUE module of the factory is published.
                   |CUE_REGISTRY = "${Project.Registry}"
                   |""".stripMargin,
            ".gitignore" ->
                s"""${Project.Folder}/.draft/
                  |.cache/
                  |.polaris/
                  |.polaris-index
                  |**/_meta/
                  |# The raw journal is the Kyo Flow store. What is kept is its export (*.export.cue).
                  |${Project.Folder}/gen/journal/*/*.gen.cue
                  |# A round in progress
                  |${Project.Folder}/initiatives/*/observed.gen.cue
                  |""".stripMargin,
            s"${Project.Folder}/polaris.yaml" ->
                s"""# @what: the portal of the project. cueverge site build vets the project, then Polaris renders this site.
                   |dir: .
                   |index: .polaris-index
                   |site: cue://$module/portal/site
                   |""".stripMargin,
            s"${Project.Folder}/README.md" ->
                s"""# $name
                   |
                   |A project of the [cueverge](https://github.com/CyrilDesch/cueverge) software factory.
                   |
                   || Folder | Holds | Written by |
                   ||---|---|---|
                   || `frame/` | the problem, the objectives, the constraints | a person, drafted at init |
                   || `intents/` | what the project means to do | a person |
                   || `cogen/` | the rules of the project | the product agent |
                   || `sealed/` | the knowledge of the project, one package per subject | the product agent |
                   || `gen/` | the journal and the captures | the kernel only |
                   || `initiatives/` | what is built, against what, with its cases | a person |
                   || `portal/` | the site of the project | a person |
                   |
                   |```sh
                   |mise install
                   |cd cueverge && cue vet -c ./...    # the only check. CI adds -t tracked, to see a package at any depth
                   |cueverge site build               # the portal
                   |```
                   |""".stripMargin,
            s"${Project.Folder}/inventory.cue" ->
                s"""@extern(embed)
                   |
                   |// @what: the inventory of the project, read by CUE itself. The cue files of each module, embedded as text.
                   |// @why: CUE cannot list folders. Fixed-depth globs reach every package, since the layout fixes the depths.
                   |package inventory
                   |
                   |import "strings"
                   |
                   |_sealed2: _ @embed(glob=sealed/*/*.cue, type=text, allowEmptyGlob)
                   |_sealed3: _ @embed(glob=sealed/*/*/*.cue, type=text, allowEmptyGlob)
                   |_rules4:  _ @embed(glob=cogen/gen-sealed/*/*/*.cue, type=text, allowEmptyGlob)
                   |_gen3:    _ @embed(glob=gen/*/*/*.cue, type=text, allowEmptyGlob)
                   |
                   |// @what: every cue file of the modules at any depth, one path per line. CI gives it, as CUE cannot list folders.
                   |// @why: the fixed-depth globs skip a deeper package. With this list, the layout rule sees it and refuses it.
                   |// @todo: back to one @embed glob with ** once CUE accepts it, and drop this tag.
                   |_tracked: *"" | string @tag(tracked)
                   |
                   |files: {
                   |	for f, _ in _sealed2 if !strings.Contains(f, "/_meta/") {(f): true}
                   |	for f, _ in _sealed3 if !strings.Contains(f, "/_meta/") {(f): true}
                   |	for f, _ in _rules4 if !strings.Contains(f, "/_meta/") {(f): true}
                   |	for f, _ in _gen3 if !strings.Contains(f, "/_meta/") {(f): true}
                   |	for f in strings.Split(_tracked, "\\n") if f != "" && !strings.Contains(f, "/_meta/") {(f): true}
                   |}
                   |""".stripMargin,
            s"${Project.Folder}/cogen/kb/modules.cue" ->
                s"""// @what: the layout rule of the factory, judged on the inventory of this project.
                   |package kb
                   |
                   |import (
                   |	"$tool/layout"
                   |
                   |	inv "$module:inventory"
                   |)
                   |
                   |(layout.#Layout & {files: inv.files})...
                   |""".stripMargin,
            s"${Project.Folder}/cogen/journal/init/exports.cue" ->
                s"""// @what: the exports of the init journal, computed from the raw journal by the factory rules.
                   |// @invariant: every export file unifies with what the raw journal gives. The kernel applies it when it writes an export.
                   |@if(journalraw)
                   |
                   |package journal
                   |
                   |import (
                   |	"$tool/rules"
                   |
                   |	g "$module/gen/journal/init:journal"
                   |)
                   |
                   |// @why: before the first export, the journal has no exports field, and before a Claude trace no traces field.
                   |_g: {executions: [string]: _, traces: [string]: _, exports: {...}} & g
                   |exports: _g.exports & (rules.#Exports & {executions: _g.executions, traces: _g.traces}).out
                   |""".stripMargin,
            s"${Project.Folder}/frame/frame.cue" -> frame(ujson.Obj("problem" -> problem, "objectives" -> ujson.Obj(), "constraints" -> ujson.Obj()), ""),
            s"${Project.Folder}/intents/intents.cue" -> intents(module, ujson.Obj(), ""),
            s"${Project.Folder}/portal/site.cue" ->
                s"""// @what: the portal of the project. polaris.yaml names this value, and polaris site build checks its shape.
                   |package portal
                   |
                   |import (
                   |	p "$tool/portal"
                   |	fr "$module/frame"
                   |	ints "$module/intents"
                   |)
                   |
                   |site: {
                   |	title: ${str(name)}
                   |	groups: [{title: "Project", pages: [(p.#FramePage & {#frame: fr.frame, #intents: ints.intents}).out]}]
                   |}
                   |""".stripMargin,
            ".github/workflows/cueverge.yml" ->
                """# @what: vets the project on every push to main and every pull request. cue vet is the only check.
                  |# @todo: the runner must reach the registry of the factory module (ghcr.io) before this job can pass.
                  |name: cueverge
                  |on:
                  |  push:
                  |    branches: [main]
                  |  pull_request:
                  |permissions:
                  |  contents: read
                  |jobs:
                  |  vet:
                  |    runs-on: ubuntu-24.04
                  |    steps:
                  |      - uses: actions/checkout@v4
                  |      - uses: jdx/mise-action@v2
                  |        with:
                  |          install_args: github:cue-lang/cue
                  |      # @why: the list of every cue file lets the layout rule see a package at any depth.
                  |      - run: cue vet -c -t tracked="$(find sealed cogen/gen-sealed gen -name '*.cue' -not -path '*/_meta/*' 2>/dev/null)" ./...
                  |        working-directory: cueverge
                  |""".stripMargin
        )

    // @what: what the scaffold adds to a file that exists. Only the lines that the project needs and lacks. Other files stay as they are.
    // @invariant: idempotent. Merging the result again changes nothing.
    def merge(rel: String, before: String, wanted: String): String = rel match
        case ".gitignore" =>
            val have    = before.linesIterator.map(_.trim).toSet
            val missing = wanted.linesIterator.filter(l => l.trim.nonEmpty && !l.startsWith("#") && !have.contains(l.trim)).toSeq
            if missing.isEmpty then before
            else before.stripSuffix("\n") + "\n\n# cueverge\n" + missing.mkString("", "\n", "\n")
        case "mise.toml" =>
            val tools = wanted.linesIterator.dropWhile(_ != "[tools]").drop(1).takeWhile(l => l.trim.nonEmpty && !l.startsWith("[")).toSeq
            val key   = (l: String) => l.takeWhile(_ != '=').trim
            val have  = before.linesIterator.map(key).toSet
            val addTools = tools.filterNot(l => have.contains(key(l)))
            val env      = s"CUE_REGISTRY = \"${Project.Registry}\""
            val withTools =
                if addTools.isEmpty then before
                else if before.linesIterator.contains("[tools]") then before.replaceFirst("(?m)^\\[tools\\]$", java.util.regex.Matcher.quoteReplacement(("[tools]" +: addTools).mkString("\n")))
                else before.stripSuffix("\n") + "\n\n[tools]\n" + addTools.mkString("", "\n", "\n")
            if have.contains("CUE_REGISTRY") then withTools
            else if withTools.linesIterator.contains("[env]") then withTools.replaceFirst("(?m)^\\[env\\]$", java.util.regex.Matcher.quoteReplacement(s"[env]\n$env"))
            else withTools.stripSuffix("\n") + s"\n\n[env]\n$env\n"
        case r if r == s"${Project.Folder}/cue.mod/module.cue" =>
            if before.contains(Project.Module) then before
            else before.stripSuffix("\n") + s"\ndeps: ${str(Project.Module)}: v: \"v${Project.Version}\"\n"
        case _ => before

    // @what: frame/frame.cue. Before the approval it holds the problem only.
    def frame(value: ujson.Value, hash: String): String =
        val tool = Project.Module.stripSuffix("@v0")
        val origin = if hash.isEmpty then "// @what: the problem as the person stated it at init. The objectives and constraints come with the approval."
            else s"// @what: the frame as a person approved it at init, draft $hash."
        s"""$origin
           |// @invariant: a person edits the frame. An agent proposes, a person approves.
           |package frame
           |
           |import f "$tool/frame"
           |
           |frame: f.#Frame & ${ujson.write(value, indent = 1)}
           |""".stripMargin

    // @what: intents/intents.cue. Each intent serves an objective of the frame.
    def intents(module: String, value: ujson.Value, hash: String): String =
        val tool = Project.Module.stripSuffix("@v0")
        val origin = if hash.isEmpty then "// @what: what the project means to do. Empty until a person approves the draft of init."
            else s"// @what: the intents as a person approved them at init, draft $hash."
        s"""$origin
           |package intents
           |
           |import (
           |	f "$tool/frame"
           |	fr "$module/frame"
           |)
           |
           |intents: ${ujson.write(value, indent = 1)}
           |
           |served: (f.#Intents & {objectives: fr.frame.objectives, "intents": intents}).served
           |""".stripMargin
end Templates
