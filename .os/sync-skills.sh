#!/bin/sh
# Makes .claude/skills show the same skills as .agents/skills (the master copy).
#   Mac and Linux: a link, so it is always up to date.
#   Windows, or anywhere links don't work: a full copy, refreshed every time this runs.
# The startup hook runs this by itself. You can also run it by hand: sh .os/sync-skills.sh
#
# Never edit skills inside .claude/skills. Edit them in .agents/skills.
# .claude/skills is never uploaded to GitHub (it's in .gitignore).
#
# Options: --copy  always make a copy instead of a link
#          --quiet only print "changed" when something was created or refreshed

quiet=false
mode=auto
for arg in "$@"; do
  case "$arg" in
    --quiet) quiet=true ;;
    --copy) mode=copy ;;
  esac
done

say() { [ "$quiet" = true ] || echo "$1"; }

root="$(cd "$(dirname "$0")/.." && pwd)" || exit 1
cd "$root" || exit 1

src=".agents/skills"
dst=".claude/skills"

if [ ! -d "$src" ]; then
  say "No .agents/skills folder found, nothing to do."
  exit 1
fi
mkdir -p .claude

case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*) mode=copy ;;   # Windows: links need special rights, use a copy
esac

if [ "$mode" = auto ]; then
  if [ -L "$dst" ] && [ -d "$dst/" ]; then
    say "Claude Code already sees the skills (link in place)."
    exit 0
  fi
  rm -rf "$dst"   # an old copy, a broken link or a stray file
  ln -s ../.agents/skills "$dst" 2>/dev/null
  if [ -L "$dst" ] && [ -d "$dst/" ]; then
    [ "$quiet" = true ] && echo changed || echo "Linked .claude/skills to .agents/skills."
    exit 0
  fi
  rm -rf "$dst"   # the link didn't work: fall back to a copy
fi

rm -rf "$dst"
cp -R "$src" "$dst"
[ "$quiet" = true ] && echo changed || echo "Copied .agents/skills into .claude/skills."
exit 0
