#!/bin/sh
# Runs by itself every time someone opens a new AI session in this folder
# (Claude Code, Codex and Antigravity all call it, through git, so it works on Mac and Windows).
#
# What it does:
#   1. Makes sure Claude Code can see the skills (.claude/skills = link or copy of .agents/skills).
#   2. Turns on the secret check that runs before every commit.
#   3. Downloads the latest version of the company's OS from GitHub.
#   4. Notes the session and refreshes the data for the 3D explorer (explorer/index.html).
# It stays silent when everything works and says one short line when something fails.
#
# Usage: sh .os/session-start.sh <claude|codex|antigravity>

tool="${1:-claude}"
root="$(cd "$(dirname "$0")/.." && pwd)" || exit 0
cd "$root" || exit 0

reload=false
message=""   # shown to the person (only when something went wrong)
context=""   # passed to the AI only

# Turns any text into a JSON string value.
json_str() {
  printf '%s' "$1" | awk 'BEGIN { ORS = "" } {
    gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, " "); gsub(/\r/, "")
    if (NR > 1) printf "\\n"
    print
  }'
}

# 1. Skills for Claude Code
if [ "$(sh .os/sync-skills.sh --quiet 2>/dev/null)" = "changed" ]; then
  reload=true
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # 2. Secret check before every commit
  if [ "$(git config --get core.hooksPath)" != ".os/git-hooks" ]; then
    git config core.hooksPath .os/git-hooks 2>/dev/null
  fi

  # 3. Download the latest version
  branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
  if [ "$branch" != "main" ]; then
    message="This copy is on \"${branch:-no branch}\", not main, so it was not updated. The OS only works on main: ask the AI to switch back to main."
  elif ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    no_remote=true # Nothing to download from yet (a brand-new copy with no GitHub link). Stay quiet.
  else
    before="$(git rev-parse HEAD 2>/dev/null)"
    output="$(GIT_TERMINAL_PROMPT=0 \
      GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=10}" \
      GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=15 \
      git pull --ff-only --quiet 2>&1)"
    if [ $? -ne 0 ]; then
      case "$output" in
        *"Not possible to fast-forward"*|*"diverg"*)
          message="Not updated: this computer has saved changes that aren't on GitHub yet, and GitHub has newer changes too. Ask the AI to run the sync skill to combine them." ;;
        *"would be overwritten"*|*"local changes"*|*"untracked working tree files"*)
          message="Not updated: you have unsaved edits to files that were also changed on GitHub. Nothing was touched. Ask the AI what to do." ;;
        *"Could not resolve host"*|*"unable to access"*|*"timed out"*|*"Connection"*|*"Operation too slow"*)
          message="Not updated: couldn't reach GitHub (is the internet on?). You're working on the version from your last update." ;;
        *"Authentication"*|*"Permission denied"*|*"could not read Username"*|*"403"*|*"Repository not found"*|*"terminal prompts disabled"*)
          message="Not updated: GitHub didn't let this computer in. Check you are signed in (run: gh auth login) and that you accepted the invite to the company's repo." ;;
        *)
          message="Not updated: the update check failed ($(printf '%s' "$output" | head -n 1))." ;;
      esac
    else
      after="$(git rev-parse HEAD 2>/dev/null)"
      if [ "$before" != "$after" ]; then
        changed="$(git diff --name-only "$before" "$after" 2>/dev/null)"
        context="The OS was updated from GitHub at session start. Changed files: $(printf '%s' "$changed" | tr '\n' ' ')"
        if printf '%s\n' "$changed" | grep -q '^AGENTS\.md$'; then
          context="$context. AGENTS.md changed: read it again before doing anything else."
        fi
        if printf '%s\n' "$changed" | grep -q '^\.agents/skills/'; then
          sh .os/sync-skills.sh --quiet >/dev/null 2>&1
          reload=true
        fi
      fi
    fi
  fi
fi

# 4. Note this session for the explorer's "Right now" line, and refresh its data
#    (explorer/session.js and explorer/data.js stay on this computer, never uploaded)
if [ -n "$message" ]; then s_ok=false; s_note="$message"
elif [ -n "${no_remote:-}" ]; then s_ok=true; s_note="Not connected to GitHub yet."
elif [ -n "${changed:-}" ]; then s_ok=true; s_note="Downloaded $(printf '%s\n' "$changed" | grep -c .) changed files from teammates."
else s_ok=true; s_note="Up to date with GitHub."
fi
mkdir -p explorer
printf 'window.AIOS_SESSION = { "tool": "%s", "started": "%s", "ok": %s, "note": "%s" };\n' \
  "$(json_str "$tool")" "$(date '+%Y-%m-%d %H:%M')" "$s_ok" "$(json_str "$s_note")" > explorer/session.js 2>/dev/null
sh .os/build-explorer.sh --quiet >/dev/null 2>&1

if [ -n "$message" ]; then
  context="The automatic update at the start of this session failed: $message${context:+ $context}"
fi

# Nothing to say: stay silent.
if [ -z "$message" ] && [ -z "$context" ] && [ "$reload" = false ]; then
  exit 0
fi

case "$tool" in
  antigravity)
    # Antigravity can only pass text to the AI, so the AI tells the person.
    [ -z "$context" ] && exit 0
    [ -n "$message" ] && context="$context Tell the user this in one short, plain sentence in your first reply."
    printf '{"injectSteps":[{"ephemeralMessage":"%s"}]}\n' "$(json_str "$context")"
    ;;
  *)
    out='{'
    [ -n "$message" ] && out="$out\"systemMessage\":\"$(json_str "$message")\","
    out="$out\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\""
    [ -n "$context" ] && out="$out,\"additionalContext\":\"$(json_str "$context")\""
    [ "$tool" = "claude" ] && [ "$reload" = true ] && out="$out,\"reloadSkills\":true"
    out="$out}}"
    printf '%s\n' "$out"
    ;;
esac
exit 0
