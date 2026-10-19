#!/bin/sh
# Collects what's in this AI OS (skills, context files, team, automations, recent changes)
# into explorer/data.js, so the 3D explorer (explorer/index.html) shows this company's real OS.
# The startup check runs this by itself. You can also run it by hand: sh .os/build-explorer.sh
# explorer/data.js stays on this computer (it's in .gitignore). It never holds keys or emails.

root="$(cd "$(dirname "$0")/.." && pwd)" || exit 1
cd "$root" || exit 1
mkdir -p explorer

# Turns text into a JSON string value (with quotes).
j() {
  printf '%s' "$1" | awk 'BEGIN { ORS = ""; printf "\"" } {
    gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, " "); gsub(/\r/, ""); gsub(/</, "\\u003c")
    if (NR > 1) printf "\\n"
    print
  } END { printf "\"" }'
}

# Prints the lines between <!-- company:NAME:start --> and <!-- company:NAME:end --> in a file.
section() {
  [ -f "$2" ] || return 0
  tr -d '\r' < "$2" | awk -v n="$1" '
    $0 ~ "^[[:space:]]*(<!--|#)[[:space:]]*company:" n ":start" { on = 1; next }
    $0 ~ "^[[:space:]]*(<!--|#)[[:space:]]*company:" n ":end" { on = 0 }
    on { print }'
}

# Table rows of a markdown table (skips the header and the |---| line), cells separated by a tab.
rows() {
  awk '/^[[:space:]]*\|/ {
    line = $0; sub(/^[[:space:]]*\|/, "", line); sub(/\|[[:space:]]*$/, "", line)
    n = split(line, c, "|"); out = ""
    for (i = 1; i <= n; i++) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", c[i]); gsub(/`/, "", c[i]); out = out (i > 1 ? "\t" : "") c[i] }
    if (out ~ /^-+(\t-+)*$/ || out ~ /^:?-+/) next
    count++
    if (count == 1) next
    print out
  }'
}

cell() { printf '%s' "$1" | awk -F '\t' -v i="$2" '{ print $i }'; }

about="$(section about AGENTS.md | awk 'NF')"
set_up=true
[ -d context ] || set_up=false
case "$about" in *"Not set up yet"*|"") set_up=false; about="" ;; esac

name="$(printf '%s' "$about" | head -n 1 | sed -n 's/.*\*\*\([^*][^*]*\)\*\*.*/\1/p')"
[ -z "$name" ] && name="$(printf '%s' "$about" | head -n 1 | sed -n -E 's/^(.{1,60}) (is|are) .*/\1/p')"
[ -z "$name" ] && name="Your company"
about_plain="$(printf '%s' "$about" | sed 's/\*\*//g')"

version="$(grep -E '"version":' .os/manifest.json 2>/dev/null | head -n 1 | sed -E 's/.*"version": *"([^"]*)".*/\1/')"
template_skills="$(grep -E '"skills":' .os/manifest.json 2>/dev/null | head -n 1 | sed -E 's/.*\[(.*)\].*/\1/' | tr ',' '\n' | tr -d ' "')"
skill_rows="$(tr -d '\r' < AGENTS.md 2>/dev/null | rows)"

# The company's GitHub address, as a plain https link (any login details in it are removed)
repo_url="$(git remote get-url origin 2>/dev/null | sed -E 's#^git@([^:]+):#https://\1/#; s#^ssh://git@([^/]+)/#https://\1/#; s#^(https?://)[^/@]+@#\1#')"
case "$repo_url" in https://*) ;; *) repo_url="" ;; esac
template_url="$(grep -E '"upstream":' .os/manifest.json 2>/dev/null | head -n 1 | sed -E 's/.*"upstream": *"([^"]*)".*/\1/')"

# Who is looking: the git email on this computer, matched with team.md (name and role only)
me="$(git config user.email 2>/dev/null | tr 'A-Z' 'a-z')"
viewer=""
if [ -n "$me" ] && [ -f team.md ]; then
  viewer="$(tr -d '\r' < team.md | rows | awk -F '\t' -v e="$me" 'tolower($3) == e || tolower($2) == e { print $1 "\t" $5; exit }')"
fi

inbox_count="$(find inbox -type f ! -name .gitkeep 2>/dev/null | wc -l | tr -d ' ')"
has_env=false; [ -f .env ] && has_env=true

{
  printf 'window.AIOS_DATA = {\n'
  printf '  "generated": %s,\n' "$(j "$(date '+%Y-%m-%d %H:%M')")"
  printf '  "setUp": %s,\n' "$set_up"
  printf '  "company": { "name": %s, "about": %s },\n' "$(j "$name")" "$(j "$about_plain")"
  printf '  "version": %s,\n' "$(j "${version:-unknown}")"
  printf '  "inboxCount": %s,\n' "${inbox_count:-0}"
  printf '  "hasEnv": %s,\n' "$has_env"
  printf '  "repoUrl": %s,\n' "$(j "$repo_url")"
  printf '  "templateUrl": %s,\n' "$(j "$template_url")"
  if [ -n "$viewer" ]; then
    printf '  "viewer": { "name": %s, "role": %s },\n' "$(j "$(cell "$viewer" 1)")" "$(j "$(cell "$viewer" 2)")"
  else
    printf '  "viewer": null,\n'
  fi

  # Routing table: which file answers which kind of question
  printf '  "routing": ['
  first=true
  section routing AGENTS.md | rows | while IFS= read -r r; do
    q="$(cell "$r" 1)"; f="$(cell "$r" 2)"
    case "$q" in ""|"(filled in by setup-os)") continue ;; esac
    $first || printf ','; first=false
    printf '\n    { "question": %s, "file": %s }' "$(j "$q")" "$(j "$f")"
  done
  printf '\n  ],\n'

  # Context files
  printf '  "context": ['
  first=true
  if [ -d context ]; then
    find context -type f -name '*.md' | LC_ALL=C sort | while IFS= read -r f; do
      title="$(tr -d '\r' < "$f" | sed -n 's/^# //p' | head -n 1)"
      summary="$(tr -d '\r' < "$f" | awk '/<!--/ { c = 1 } c { if (/-->/) c = 0; next } NF && !/^#/ && !/^\|/ && !/^- \*\*.*:\*\*[[:space:]]*$/ { print; exit }' | cut -c1-160)"
      lines="$(wc -l < "$f" | tr -d ' ')"
      $first || printf ','; first=false
      printf '\n    { "file": %s, "title": %s, "summary": %s, "lines": %s }' "$(j "$f")" "$(j "$title")" "$(j "$summary")" "$lines"
    done
  fi
  printf '\n  ],\n'

  # Skills
  printf '  "skills": ['
  first=true
  for d in .agents/skills/*/; do
    [ -f "$d/SKILL.md" ] || continue
    s="$(basename "$d")"
    desc="$(tr -d '\r' < "$d/SKILL.md" | awk '/^---/ { n++; next } n == 1 && /^description:/ { sub(/^description:[[:space:]]*/, ""); gsub(/^["'"'"']|["'"'"']$/, ""); print; exit }')"
    row="$(printf '%s\n' "$skill_rows" | awk -F '\t' -v s="$s" '$1 == s { print; exit }')"
    who="$(cell "$row" 2)"; when="$(cell "$row" 3)"
    tmpl=false; printf '%s\n' "$template_skills" | grep -qx "$s" && tmpl=true
    # The skill's main steps: its "## " headings, without numbering
    steps="$(tr -d '\r' < "$d/SKILL.md" | awk '/^```/ { f = !f; next } !f && /^## / { sub(/^## +/, ""); sub(/^([0-9]+|[a-z])[.)] +/, ""); print }' | head -n 10 | while IFS= read -r h; do printf '%s,' "$(j "$h")"; done)"
    $first || printf ','; first=false
    printf '\n    { "name": %s, "who": %s, "when": %s, "description": %s, "template": %s, "steps": [%s] }' \
      "$(j "$s")" "$(j "$who")" "$(j "$when")" "$(j "$desc")" "$tmpl" "${steps%,}"
  done
  printf '\n  ],\n'

  # Team: names and roles only
  printf '  "team": ['
  first=true
  if [ -f team.md ]; then
    tr -d '\r' < team.md | rows | while IFS= read -r r; do
      n="$(cell "$r" 1)"; role="$(cell "$r" 5)"
      [ -n "$n" ] || continue
      $first || printf ','; first=false
      printf '\n    { "name": %s, "role": %s }' "$(j "$n")" "$(j "$role")"
    done
  fi
  printf '\n  ],\n'

  # Automations
  printf '  "automations": ['
  first=true
  if [ -f automations.md ]; then
    tr -d '\r' < automations.md | rows | while IFS= read -r r; do
      n="$(cell "$r" 1)"
      [ -n "$n" ] || continue
      $first || printf ','; first=false
      printf '\n    { "name": %s, "what": %s, "skill": %s, "how": %s, "worksIn": %s, "owner": %s, "status": %s }' \
        "$(j "$n")" "$(j "$(cell "$r" 2)")" "$(j "$(cell "$r" 3)")" "$(j "$(cell "$r" 4)")" "$(j "$(cell "$r" 5)")" "$(j "$(cell "$r" 6)")" "$(j "$(cell "$r" 7)")"
    done
  fi
  printf '\n  ],\n'

  # Recent changes
  printf '  "recent": ['
  first=true
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git log -8 --date=short --pretty=tformat:'%ad%x09%an%x09%s' 2>/dev/null | while IFS= read -r r; do
      $first || printf ','; first=false
      printf '\n    { "date": %s, "author": %s, "subject": %s }' "$(j "$(cell "$r" 1)")" "$(j "$(cell "$r" 2)")" "$(j "$(cell "$r" 3)")"
    done
  fi
  printf '\n  ],\n'

  # What this computer is working on: files changed but not saved yet, and saves not uploaded yet
  printf '  "work": { "unsaved": ['
  ahead=0
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git status --porcelain=v1 --untracked-files=all 2>/dev/null | cut -c4- | sed 's/^"//; s/"$//; s/.* -> //' | grep -v '^explorer/' | head -n 40 | {
      first=true
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        $first || printf ','; first=false
        printf '%s' "$(j "$f")"
      done
    }
    ahead="$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
  fi
  printf '], "notUploaded": %s },\n' "${ahead:-0}"

  # Lately on the team: each person's latest saved change
  printf '  "activity": ['
  first=true
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git log -200 --date=short --pretty=tformat:'%an%x09%ad%x09%s' 2>/dev/null | awk -F '\t' '!seen[$1]++' | head -n 5 | while IFS= read -r r; do
      $first || printf ','; first=false
      printf '\n    { "author": %s, "date": %s, "subject": %s }' "$(j "$(cell "$r" 1)")" "$(j "$(cell "$r" 2)")" "$(j "$(cell "$r" 3)")"
    done
  fi
  printf '\n  ]\n'
  printf '};\n'
} > "${TMPDIR:-/tmp}/aios-data.$$" && mv "${TMPDIR:-/tmp}/aios-data.$$" explorer/data.js

[ "${1:-}" = "--quiet" ] || echo "Updated explorer/data.js. Open explorer/index.html to see your AI OS."
exit 0
