#!/bin/sh
# Helper for the update-os skill: compares this company's copy with a newer template version.
#
#   sh update-os.sh check  <ref>          what would change (ref is usually upstream/main)
#   sh update-os.sh diff   <ref> <path>   the company's version next to the new template version
#   sh update-os.sh apply  <ref> <path>   take the new template version (company sections are kept)
#   sh update-os.sh remove <ref> <path>   delete a template file the new version no longer has
#   sh update-os.sh finish <ref>          record the new version in .os/manifest.json
#   sh update-os.sh fingerprint <path>    print a file's fingerprint
#
# How it decides: .os/manifest.json stores a fingerprint of every template file as it was
# installed. If the file on disk still has that fingerprint, the company never edited it and it
# is safe to replace. If not, the company changed it and a person has to decide.
#
# Company sections: text between "company:<name>:start" and "company:<name>:end" markers
# (for example in AGENTS.md) belongs to the company. It is left out of fingerprints and is
# always carried over into the new version.

root="$(cd "$(dirname "$0")/../../../.." && pwd)" || exit 1
cd "$root" || exit 1

cmd="${1:-}"
ref="${2:-}"
path="${3:-}"

# A marker is a line that holds nothing but the marker, as an HTML or # comment, for example
#   <!-- company:about:start -->     or     # company:extra:end
# Text that only mentions a marker inside a sentence doesn't count.
START_RE='^[[:space:]]*(<!--|#)[[:space:]]*company:[a-z0-9-]+:start[[:space:]]*(-->)?[[:space:]]*$'
END_RE='^[[:space:]]*(<!--|#)[[:space:]]*company:[a-z0-9-]+:end[[:space:]]*(-->)?[[:space:]]*$'

normalize() {
  tr -d '\r' | awk -v s="$START_RE" -v e="$END_RE" '
    $0 ~ s { print; skip = 1; next }
    $0 ~ e { skip = 0 }
    !skip { print }'
}

fp_file() {
  if [ -f "$1" ]; then normalize < "$1" | git hash-object --stdin --no-filters; else echo MISSING; fi
}

fp_ref() {
  if git cat-file -e "$ref:$1" 2>/dev/null; then
    git show "$ref:$1" | normalize | git hash-object --stdin --no-filters
  else
    echo MISSING
  fi
}

# Lists "path fingerprint" lines from a manifest given on stdin.
manifest_files() {
  tr -d '\r' | sed -n '/"files": *{/,/}/p' \
    | grep -E '^[[:space:]]*"[^"]+": *"[0-9a-f]{40}"' \
    | sed -E 's/^[[:space:]]*"([^"]+)": *"([0-9a-f]{40})".*/\1 \2/'
}

manifest_value() { tr -d '\r' | grep -E "\"$1\":" | head -n 1 | sed -E "s/.*\"$1\": *\"([^\"]*)\".*/\1/"; }

manifest_skills() {
  tr -d '\r' | grep -E '"skills":' | head -n 1 | sed -E 's/.*\[(.*)\].*/\1/' | tr ',' '\n' | tr -d ' "'
}

# Files the company owns. update-os never writes, changes or deletes these.
protected() {
  case "$1" in
    context/*|team.md|automations.md|scripts/*|inbox/*|outputs/*|.env|.env.*|.claude/skills|.claude/skills/*|.claude/settings.local.json|.os/manifest.json|explorer/data.js|explorer/session.js|explorer/live.js|explorer/apps.js|explorer/live/*) return 0 ;;
  esac
  return 1
}

# Files that run by themselves on people's computers. Changes to these need a separate yes.
sensitive() {
  case "$1" in
    .claude/settings.json|.codex/*|.agents/hooks.json|.os/*|.gitattributes|*.sh|*.ps1|*/scripts/*) return 0 ;;
  esac
  return 1
}

need_ref() {
  if [ -z "$ref" ] || ! git rev-parse --verify --quiet "$ref" >/dev/null; then
    echo "Unknown version \"$ref\". Run: git fetch upstream   then use upstream/main." >&2
    exit 1
  fi
}

# Is this path part of the template, either before or after the update?
template_path() {
  { cat .os/manifest.json 2>/dev/null | manifest_files; git show "$ref:.os/manifest.json" 2>/dev/null | manifest_files; } \
    | awk -v p="$1" '$1 == p { found = 1 } END { exit !found }'
}

# Puts the company's sections from the local file into the new template text (stdin).
merge_sections() {
  awk -v localfile="$1" -v s="$START_RE" -v e="$END_RE" '
    BEGIN {
      while ((getline line < localfile) > 0) {
        sub(/\r$/, "", line)
        if (line ~ s) {
          match(line, /company:[a-z0-9-]+:start/)
          cur = substr(line, RSTART + 8, RLENGTH - 14); have[cur] = 1; body[cur] = ""; continue
        }
        if (cur != "" && line ~ e) { cur = ""; continue }
        if (cur != "") body[cur] = body[cur] line "\n"
      }
    }
    { sub(/\r$/, "") }
    $0 ~ s {
      print
      match($0, /company:[a-z0-9-]+:start/); name = substr($0, RSTART + 8, RLENGTH - 14)
      if (name in have) { printf "%s", body[name]; skip = 1 }
      next
    }
    $0 ~ e { skip = 0; print; next }
    !skip { print }'
}

case "$cmd" in
  fingerprint)
    fp_file "$2"
    ;;

  check)
    need_ref
    local_version="$(manifest_value version < .os/manifest.json)"
    new_version="$(git show "$ref:.os/manifest.json" 2>/dev/null | manifest_value version)"
    echo "Your version: ${local_version:-unknown}"
    echo "New version:  ${new_version:-unknown}"
    if [ -z "$new_version" ]; then echo "The new version has no .os/manifest.json. Stop and tell an admin."; exit 1; fi
    echo
    echo "STATUS	FILE	NOTE"

    tmp="${TMPDIR:-/tmp}/aios-update.$$"
    cat .os/manifest.json | manifest_files > "$tmp.local"
    git show "$ref:.os/manifest.json" | manifest_files > "$tmp.new"

    # Every file in the old or new template
    cut -d' ' -f1 "$tmp.local" "$tmp.new" | sort -u | while IFS= read -r p; do
      [ -n "$p" ] || continue
      protected "$p" && continue
      installed="$(awk -v p="$p" '$1 == p { print $2 }' "$tmp.local")"
      in_new="$(awk -v p="$p" '$1 == p { print $2 }' "$tmp.new")"
      current="$(fp_file "$p")"
      flag=""; sensitive "$p" && flag="RUNS-BY-ITSELF: needs a separate yes"
      if [ -z "$installed" ]; then
        # New template file
        if [ "$current" = MISSING ]; then status=NEW
        elif [ "$current" = "$(fp_ref "$p")" ]; then status=SAME
        else status=CLASH; flag="the company already has its own file here${flag:+; $flag}"; fi
      elif [ -z "$in_new" ]; then
        # The new template no longer has this file
        if [ "$current" = MISSING ]; then status=SAME
        elif [ "$current" = "$installed" ]; then status=REMOVE
        else status=REVIEW; flag="the template dropped it, but the company edited it${flag:+; $flag}"; fi
      else
        upstream="$(fp_ref "$p")"
        if [ "$upstream" = "$installed" ] || [ "$current" = "$upstream" ]; then status=SAME
        elif [ "$current" = "$installed" ]; then status=UPDATE
        elif [ "$current" = MISSING ]; then status=REVIEW; flag="the company deleted it; the template changed it${flag:+; $flag}"
        else status=REVIEW; flag="both the company and the template changed it${flag:+; $flag}"; fi
      fi
      [ "$status" = SAME ] || printf '%s\t%s\t%s\n' "$status" "$p" "$flag"
    done

    # A new template skill with the same name as a skill the company made
    for s in $(git show "$ref:.os/manifest.json" | manifest_skills); do
      if ! manifest_skills < .os/manifest.json | grep -qx "$s" && [ -d ".agents/skills/$s" ]; then
        printf 'CLASH\t.agents/skills/%s/\tthe new template has a skill with the same name as one the company made\n' "$s"
      fi
    done
    rm -f "$tmp.local" "$tmp.new"
    echo
    echo "UPDATE = safe to replace (the company never edited it)   NEW = new template file"
    echo "REMOVE = the template dropped it (never edited)           REVIEW / CLASH = a person decides"
    ;;

  diff)
    need_ref
    [ -n "$path" ] || { echo "Which file?" >&2; exit 1; }
    tmp="${TMPDIR:-/tmp}/aios-new.$$"
    git show "$ref:$path" > "$tmp" 2>/dev/null || : > "$tmp"
    if [ -f "$path" ]; then old="$path"; else old=/dev/null; fi
    echo "--- the company's version: $path"
    echo "+++ the new template version"
    git diff --no-index --no-color -- "$old" "$tmp" | tail -n +5
    rm -f "$tmp"
    ;;

  apply)
    need_ref
    [ -n "$path" ] || { echo "Which file?" >&2; exit 1; }
    if protected "$path"; then echo "Refused: $path belongs to the company. update-os never touches it." >&2; exit 1; fi
    if ! template_path "$path"; then echo "Refused: $path is not a template file." >&2; exit 1; fi
    git cat-file -e "$ref:$path" 2>/dev/null || { echo "The new version has no $path. Use remove instead." >&2; exit 1; }
    mkdir -p "$(dirname "$path")"
    tmp="${TMPDIR:-/tmp}/aios-apply.$$"
    if [ -f "$path" ]; then git show "$ref:$path" | merge_sections "$path" > "$tmp"; else git show "$ref:$path" > "$tmp"; fi
    mv "$tmp" "$path"
    if git ls-tree "$ref" -- "$path" | grep -q '^100755'; then chmod +x "$path"; fi
    echo "Updated $path"
    ;;

  remove)
    need_ref
    [ -n "$path" ] || { echo "Which file?" >&2; exit 1; }
    if protected "$path"; then echo "Refused: $path belongs to the company. update-os never touches it." >&2; exit 1; fi
    if ! template_path "$path"; then echo "Refused: $path is not a template file." >&2; exit 1; fi
    if git cat-file -e "$ref:$path" 2>/dev/null; then echo "Refused: the new version still has $path." >&2; exit 1; fi
    rm -f "$path"
    echo "Removed $path"
    ;;

  finish)
    need_ref
    git show "$ref:.os/manifest.json" > .os/manifest.json
    echo "Recorded version $(manifest_value version < .os/manifest.json) in .os/manifest.json"
    ;;

  *)
    sed -n '2,10p' "$0"
    exit 1
    ;;
esac
