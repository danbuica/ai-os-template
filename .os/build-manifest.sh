#!/bin/sh
# For the template's maintainer only: rebuilds .os/manifest.json before releasing a new version.
# Lists every file the template owns with its fingerprint, so update-os can later tell which
# files a company has edited.
#
# Usage (in the template repo itself, never in a company's copy):
#   sh .os/build-manifest.sh 1.1.0 https://github.com/OWNER/ai-os.git
# Both arguments are optional: without them the current version and upstream address are kept.

root="$(cd "$(dirname "$0")/.." && pwd)" || exit 1
cd "$root" || exit 1

if [ -d context ] || [ -f team.md ]; then
  echo "This looks like a company's copy (context/ or team.md exists). Run this only in the empty template." >&2
  exit 1
fi

old_version="$(grep -E '"version":' .os/manifest.json 2>/dev/null | head -n 1 | sed -E 's/.*"version": *"([^"]*)".*/\1/')"
old_upstream="$(grep -E '"upstream":' .os/manifest.json 2>/dev/null | head -n 1 | sed -E 's/.*"upstream": *"([^"]*)".*/\1/')"
version="${1:-${old_version:-1.0.0}}"
upstream="${2:-${old_upstream:-https://github.com/danbuica/ai-os-template.git}}"
fingerprint=".agents/skills/update-os/scripts/update-os.sh"

# Files the template creates once but then belong to the company: not listed.
files="$(find . -type f \
  ! -path './.git/*' \
  ! -path './context/*' \
  ! -path './inbox/*' \
  ! -path './outputs/*' \
  ! -path './scripts/*' \
  ! -path './.claude/skills/*' \
  ! -name '.DS_Store' ! -name 'Thumbs.db' ! -name 'desktop.ini' \
  ! -path './.env' ! -path './.env.example' \
  ! -path './.claude/settings.local.json' \
  ! -path './.os/manifest.json' \
  ! -path './explorer/data.js' \
  ! -path './explorer/session.js' \
  ! -path './explorer/live.js' \
  ! -path './explorer/apps.js' \
  ! -path './explorer/live/*' \
  ! -path './explorer/extras.js' \
  | sed 's|^\./||' | LC_ALL=C sort)"

skills="$(find .agents/skills -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | LC_ALL=C sort | awk '{ printf "%s\"%s\"", (NR > 1 ? ", " : ""), $0 }')"

{
  echo '{'
  echo '  "template": "ai-os",'
  echo "  \"version\": \"$version\","
  echo "  \"upstream\": \"$upstream\","
  echo "  \"skills\": [$skills],"
  echo '  "files": {'
  count="$(printf '%s\n' "$files" | grep -c .)"
  n=0
  printf '%s\n' "$files" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    n=$((n + 1))
    comma=","; [ "$n" -eq "$count" ] && comma=""
    echo "    \"$f\": \"$(sh "$fingerprint" fingerprint "$f")\"$comma"
  done
  echo '  }'
  echo '}'
} > .os/manifest.json.tmp && mv .os/manifest.json.tmp .os/manifest.json

echo "Wrote .os/manifest.json: version $version, $(printf '%s\n' "$files" | grep -c .) files."
