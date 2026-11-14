#!/usr/bin/env bash
# @what: fixes only wrap-safe tagged comment width failures and exact missing @ref: additions reported by comment-tags-staged.sh.
# @why: source and line candidates come from the staged-comment linter, so a full prek run never rewrites unrelated comment blocks.
# @ref: @/.agents/scripts/comment-tags-staged.sh
set -uo pipefail
# @why: bash 3.2 and BSD awk, as on macOS. Bash 3.2 has no associative array, so the block logic lives in awk.

root=$(git rev-parse --show-toplevel) || exit 0
cd "$root" || exit 0
tmp=$(mktemp -d) || exit 0
trap 'rm -rf "$tmp"' EXIT
tab=$'\t'

# @what: the comment marker of a path, empty when the path has no comment style.
marker() {
  if [[ $1 =~ \.(scala|sc|mill|java|kt|ts|tsx|js|mjs|go|rs|cue)$ ]]; then
    echo '//'
  elif [[ $1 =~ (\.(sh|bash|zsh|py|toml|ya?ml)$)|(^|/)(Dockerfile|Makefile) ]]; then
    echo '#'
  elif [[ $1 =~ \.sql$ ]]; then
    echo '--'
  fi
}

usable=()
for f in "$@"; do
  f=${f#"$root"/}
  f=${f#./}
  [[ -n $(marker "$f") && -f $f ]] && usable+=("$f")
done
[[ ${#usable[@]} -eq 0 ]] && exit 0

# @what: a snapshot of each file, so a file the user edits while the hook runs is left alone.
mkdir -p "$tmp/snap"
i=0
for f in "${usable[@]}"; do
  cp "$f" "$tmp/snap/$i"
  printf '%s\t%s\n' "$i" "$f" >>"$tmp/index"
  i=$((i + 1))
done

# @what: the findings of the linter, as file, kind (W width, A addition), 1-based line and reference.
"$root/.agents/scripts/comment-tags-staged.sh" "${usable[@]}" 2>/dev/null |
  sed -nE \
    -e "s/^(.*):([0-9]+): mentions .+\\. Add (@ref: @\\/[^ ]+) to this block\\.\$/\\1${tab}A${tab}\\2${tab}\\3/p" \
    -e "s/^(.*):([0-9]+): line has [0-9]+ columns, limit is 150\\..*/\\1${tab}W${tab}\\2${tab}/p" >"$tmp/findings"
[[ -s $tmp/findings ]] || exit 0

# @what: the 1-based lines added in each file, as file and line. ALL when COMMENT_TAGS_AUTOFIX_ALL=1.
all=${COMMENT_TAGS_AUTOFIX_ALL:-0}
if [[ $all != 1 ]]; then
  if [[ -n ${PRE_COMMIT_FROM_REF:-} && -n ${PRE_COMMIT_TO_REF:-} ]]; then
    args=("$PRE_COMMIT_FROM_REF...$PRE_COMMIT_TO_REF")
  elif ! git diff --cached --quiet -- "${usable[@]}"; then
    args=(--cached)
  else
    args=(HEAD)
  fi
  git diff -U0 --no-color --no-ext-diff "${args[@]}" -- "${usable[@]}" | awk '
    /^\+\+\+ b\// { current = substr($0, 7); next }
    /^@@/ { line = 0; if (match($0, /\+[0-9]+/)) line = substr($0, RSTART + 1, RLENGTH - 1) + 0; next }
    /^\+/ && !/^\+\+\+/ { if (current != "") print current "\t" line; line++; next }
    !/^-/ { line++ }
  ' >"$tmp/changed"
fi

while IFS="$tab" read -r idx name; do
  awk -F'\t' -v N="$name" '$1 == N' "$tmp/findings" >"$tmp/mine"
  [[ -s $tmp/mine ]] || continue
  if [[ $all == 1 ]]; then
    permitted=ALL
  else
    permitted=$(awk -F'\t' -v N="$name" '$1 == N { printf "%s ", $2 }' "$tmp/changed")
    [[ -z $permitted ]] && continue
  fi
  cmp -s "$name" "$tmp/snap/$idx" || continue
  MARKER=$(marker "$name") PERMITTED=$permitted FINDINGS="$tmp/mine" awk '
    function lstrip(s) { sub(/^[ \t]+/, "", s); return s }
    function iscomment(i,   s) { s = lstrip(L[i]); return s == M || index(s, M " ") == 1 }
    function blank(i) { return L[i] ~ /^[ \t\r\f\v]*$/ }
    function body(i,   s) { s = substr(lstrip(L[i]), length(M) + 1); if (substr(s, 1, 1) == " ") s = substr(s, 2); return s }
    function indent(i,   s) { s = L[i]; match(s, /^[ \t]*/); return substr(s, 1, RLENGTH) }
    function secondlabel(t) {
      gsub(/`[^`]*`/, "", t)
      gsub(/[A-Za-z][A-Za-z0-9+.-]*:\/\/[^ ]*/, "", t)
      return t ~ /(^|[ (])[A-Za-z][A-Za-z0-9_.-]*:( |$)/
    }
    function blockchars(s, e,   i, c) { c = 0; for (i = s; i <= e; i++) if (iscomment(i)) c += length(body(i)); return c }
    # @what: the wrapped lines of a too-long tagged line, joined by newlines, or empty when it cannot wrap.
    function wrap(i,   c, tag, prose, first, avail, nw, w, ww, j, k, out, cur, cnt, nxt, lines) {
      c = body(i)
      if (!match(c, /^@(what|why|invariant|todo|ref|generated):( |$)/)) return ""
      tag = substr(c, 1, RLENGTH); prose = substr(c, RLENGTH + 1); sub(/ $/, "", tag)
      if (index(prose, "$> ")) return ""
      first = indent(i) M " " tag " "
      avail = 150 - length(first)
      nw = split(prose, w, /[ \t]+/)
      k = 0
      for (j = 1; j <= nw; j++) if (w[j] != "") ww[++k] = w[j]
      nw = k
      if (avail < 1) return ""
      for (j = 1; j <= nw; j++) if (length(ww[j]) > avail) return ""
      out = ""; cur = ""; cnt = 0; lines = 0
      for (j = 1; j <= nw; j++) {
        nxt = cnt + (cur != "" ? 1 : 0) + length(ww[j])
        if (cur != "" && nxt > avail) { out = out (lines ? "\n" : "") first cur; lines++; cur = ww[j]; cnt = length(ww[j]) }
        else { cur = cur (cur != "" ? " " : "") ww[j]; cnt = nxt }
      }
      if (cur != "") { out = out (lines ? "\n" : "") first cur; lines++ }
      return lines > 1 ? out : ""
    }
    BEGIN {
      M = ENVIRON["MARKER"]; BLOCK = 300
      all = ENVIRON["PERMITTED"] == "ALL"
      if (!all) { np = split(ENVIRON["PERMITTED"], p, " "); for (j = 1; j <= np; j++) permitted[p[j]] = 1 }
      while ((getline line < ENVIRON["FINDINGS"]) > 0) {
        split(line, f, "\t")
        cand[f[3] + 0] = 1
        if (f[2] == "W") width[f[3] + 0] = 1
        else { na++; aline[na] = f[3] + 0; aref[na] = f[4] }
      }
    }
    { L[NR] = $0 }
    END {
      n = NR
      # @why: a generated file is fixed in its generator, never here.
      for (i = 1; i <= n; i++) {
        if (!blank(i) && index(lstrip(L[i]), M) != 1) break
        if (index(lstrip(L[i]), M " @generated:") == 1) exit 3
      }
      nb = 0
      for (c in cand) {
        c += 0
        if (c < 1 || c > n || !iscomment(c)) continue
        s = c; while (s > 1 && (blank(s - 1) || iscomment(s - 1))) s--
        e = c; while (e < n && (blank(e + 1) || iscomment(e + 1))) e++
        if (!(s in seen)) { seen[s] = 1; nb++; bs[nb] = s; be[nb] = e }
      }
      for (b = 1; b <= nb; b++) {
        s = bs[b]; e = be[b]; last = 0; touched = all; bad = 0
        for (i = s; i <= e; i++) if (iscomment(i)) {
          last = i
          if (i in permitted) touched = 1
          if (secondlabel(body(i))) bad = 1
        }
        if (!last || !touched || bad) continue
        chars = blockchars(s, e)
        if (chars > BLOCK) continue
        nr = 0; extra = 0
        for (a = 1; a <= na; a++) if (aline[a] >= s && aline[a] <= e && !((s, aref[a]) in dup)) {
          dup[s, aref[a]] = 1; refs[++nr] = aref[a]; extra += length(aref[a])
        }
        if (chars + extra > BLOCK) continue
        for (r = 1; r <= nr; r++) after[e] = after[e] "\n" indent(last) M " " refs[r]
        for (i = s; i <= e; i++) if (i in width) { w = wrap(i); if (w != "") repl[i] = w }
      }
      for (i = 1; i <= n; i++) printf "%s%s\n", ((i in repl) ? repl[i] : L[i]), ((i in after) ? after[i] : "")
    }
  ' "$name" >"$tmp/out"
  [[ $? -eq 0 ]] || continue
  # @why: keep a missing final newline missing.
  if [[ -s $name && $(tail -c1 "$name" | od -An -c | tr -d ' ') != '\n' ]]; then
    printf '%s' "$(cat "$tmp/out")" >"$tmp/out"
  fi
  cmp -s "$tmp/out" "$name" || cat "$tmp/out" >"$name"
done <"$tmp/index"
exit 0
