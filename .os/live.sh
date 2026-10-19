#!/bin/sh
# Moves this session's robot in the 3D explorer, live.
# Claude Code, Codex and Antigravity call this (through git, so it works on Mac and Windows) when
# a session starts, when you send a message, when the AI uses a tool, when it finishes a reply,
# and when the session ends. It notes where the work is happening, for example:
#   using a skill        -> that skill's desk          company knowledge -> that file's shelf
#   team.md              -> the team table             automations.md    -> the routines board
#   inbox/               -> the inbox                  .env              -> the key safe
#   saving (git commit)  -> the safety check           uploading/downloading -> GitHub
#   a connected app (MCP) -> that app's kiosk in Connected apps
#   anything else        -> the front desk
#
# It never records what anyone typed, or full commands: only the kind of thing and which OS file or skill.
# Everything stays on this computer: explorer/live/ and explorer/live.js are never uploaded.
# explorer/live/history.tsv remembers the sessions of the last 31 days (who, which app, when, last activity)
# so the explorer can show them as workers in the lounge.
#
# Usage: sh .os/live.sh <claude|codex|antigravity> <start|prompt|invoke|expand|tool|stop|end>  (report on stdin)

app="${1:-claude}"
event="${2:-tool}"
root="$(cd "$(dirname "$0")/.." && pwd)" || exit 0
cd "$root" || exit 0

# Antigravity expects a JSON answer on every report. "{}" after a tool or a reply changes nothing.
answer() { [ "$app" = "antigravity" ] && echo '{}'; exit 0; }

input="$(cat 2>/dev/null | tr '\n\r\t' '   ')"
# Leave out paths that only describe the session itself, so they're not mistaken for OS files.
clean="$(printf '%s' "$input" | sed -E 's/"(transcript_path|transcriptPath|cwd|artifactDirectoryPath)" *: *"[^"]*"//g; s/"workspacePaths" *: *\[[^]]*\]//g')"

# The last value of a JSON text field (good enough for these small reports).
field() { printf '%s' "$input" | sed -n -E "s/.*\"$1\" *: *\"([^\"]*)\".*/\1/p" | head -n 1; }
safe() { printf '%s' "$1" | tr -d '\t"\\<>' | cut -c1-80; }

sid="$(field session_id)"
[ -n "$sid" ] || sid="$(field conversationId)"
sid="$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9-' | cut -c1-48)"
[ -n "$sid" ] || answer

mkdir -p explorer/live 2>/dev/null || answer
file="explorer/live/$sid.s"
now="$(date +%s)"

hist="explorer/live/history.tsv"
# Keeps the session in the 31-day worker history (shown as sleeping workers in the lounge)
remember() { # $1 person, $2 label
  first="$now"
  [ -f "$hist" ] && first="$(awk -F '\t' -v id="$sid" '$1 == id { print $4; exit }' "$hist")"
  [ -n "$first" ] || first="$now"
  {
    [ -f "$hist" ] && awk -F '\t' -v id="$sid" -v cut="$((now - 2678400))" '$1 != id && $5 >= cut' "$hist"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$sid" "$app" "$(safe "$1")" "$first" "$now" "$(safe "$2")"
  } > "$hist.$$" && mv "$hist.$$" "$hist"
}

regen() {
  find explorer/live -name '*.s' -mmin +1440 -exec rm -f {} + 2>/dev/null
  {
    printf 'window.AIOS_LIVE = { "updated": %s, "sessions": [' "$now"
    first=1
    for f in explorer/live/*.s; do
      [ -f "$f" ] || continue
      [ "$first" = 1 ] || printf ','
      first=0
      awk -F '\t' -v id="$(basename "$f" .s)" 'NR == 1 {
        printf "\n  {\"id\":\"%s\",\"app\":\"%s\",\"since\":%s,\"last\":%s,\"person\":\"%s\",\"state\":\"%s\",\"room\":\"%s\",\"target\":\"%s\",\"label\":\"%s\"}", id, $1, ($2 == "" ? 0 : $2), ($3 == "" ? 0 : $3), $4, $5, $6, $7, $8
      }' "$f"
    done
    printf '\n], "history": ['
    if [ -f "$hist" ]; then
      sort -t "$(printf '\t')" -k5,5nr "$hist" | head -n 80 | awk -F '\t' '{
        printf "%s\n  {\"id\":\"%s\",\"app\":\"%s\",\"person\":\"%s\",\"first\":%s,\"last\":%s,\"label\":\"%s\"}", (NR > 1 ? "," : ""), $1, $2, $3, ($4 == "" ? 0 : $4), ($5 == "" ? 0 : $5), $6
      }'
    fi
    printf '\n]};\n'
  } > "explorer/live.js.$$" && mv "explorer/live.js.$$" explorer/live.js
}

if [ "$event" = "end" ]; then
  # Only sessions that did something count. Quick helper runs, like apps.sh asking Claude Code for its
  # app list ("claude mcp list"), report an end without ever starting, and must not become workers.
  [ -f "$file" ] || answer
  p_end="$(cut -f4 "$file" 2>/dev/null | head -n 1)"
  [ -n "$p_end" ] || p_end="$(git config user.name 2>/dev/null)"
  remember "${p_end:-Someone}" "Finished"
  rm -f "$file"
  regen
  answer
fi

tn="$(field tool_name)"
[ -n "$tn" ] || tn="$(field name)"
state="working"; room="desk"; target=""; label=""

case "$event" in
  start) state="arriving"; label="Starting up" ;;
  prompt) state="thinking"; label="Thinking" ;;
  invoke)
    # Antigravity: only the first model call of a reply counts as "thinking"
    n="$(printf '%s' "$input" | sed -n -E 's/.*"invocationNum" *: *([0-9]+).*/\1/p')"
    [ "${n:-0}" = "0" ] || answer
    state="thinking"; label="Thinking" ;;
  expand)
    cn="$(field command_name)"
    if [ -n "$cn" ] && [ -d ".agents/skills/$cn" ]; then room="workshop"; target="$cn"; label="Using $cn"
    else state="thinking"; label="Thinking"; fi ;;
  stop) state="waiting"; label="Waiting for you" ;;
  tool)
    case "$tn" in
      Read|view_file|Grep|Glob|grep_search|list_dir|find_by_name|view_code_item) verb="Reading" ;;
      Edit|Write|MultiEdit|NotebookEdit|apply_patch|write_to_file|replace_file_content|multi_replace_file_content) verb="Editing" ;;
      *) verb="" ;;
    esac
    # A connected app (MCP): Claude Code and Codex name the tool mcp__<app>__<tool>, Antigravity uses call_mcp_tool
    mraw=""
    case "$tn" in
      mcp__*) mraw="$(printf '%s' "$tn" | awk -F '__' '{ print $2 }')" ;;
      call_mcp_tool) mraw="$(field ServerName)" ;;
    esac
    aid=""
    if [ -n "$mraw" ]; then
      res="$(sh .os/apps.sh used "$app" "$mraw" 2>/dev/null)"
      aid="$(printf '%s' "$res" | cut -f1)"; aname="$(printf '%s' "$res" | cut -f2)"
    fi
    sk="$(field skill)"
    sp="$(printf '%s' "$clean" | grep -o -E '\.agents/skills/[A-Za-z0-9_-]+' | head -n 1 | sed 's#.*/##')"
    cf="$(printf '%s' "$clean" | grep -o -E 'context/[A-Za-z0-9_./-]+\.md' | head -n 1)"
    if [ -n "$aid" ]; then
      room="apps"; target="$aid"; label="Using ${aname:-an app}"
    elif [ "$tn" = "Skill" ] && [ -n "$sk" ]; then
      room="workshop"; target="$sk"; label="Using $sk"
    elif [ -n "$sp" ] && [ -d ".agents/skills/$sp" ]; then
      room="workshop"; target="$sp"
      if [ "$verb" = "Editing" ]; then label="Editing the $sp skill"; else label="Using $sp"; fi
    elif [ -n "$cf" ]; then
      room="library"; target="$cf"; label="${verb:-Reading} ${cf#context/}"
    elif printf '%s' "$clean" | grep -q -E '(^|[^A-Za-z0-9_.-])team\.md'; then
      room="team"; label="${verb:-Checking} the team list"
    elif printf '%s' "$clean" | grep -q -E 'automations\.md'; then
      room="auto"; label="${verb:-Checking} the automations list"
    elif printf '%s' "$clean" | grep -q -E '(^|[^A-Za-z0-9_.-])inbox/'; then
      room="inbox"; label="Reading the inbox"
    elif printf '%s' "$clean" | grep -q -E '(^|[^A-Za-z0-9_.-])\.env([^.A-Za-z0-9_-]|$)'; then
      room="safe"; label="At the key safe"
    elif printf '%s' "$clean" | grep -q -E 'git( -C [^ ]+)? push'; then
      room="github"; label="Uploading to GitHub"
    elif printf '%s' "$clean" | grep -q -E 'git( -C [^ ]+)? commit'; then
      room="gate"; label="Saving (safety check)"
    elif printf '%s' "$clean" | grep -q -E 'git( -C [^ ]+)? (pull|fetch|clone)'; then
      room="github"; label="Downloading from GitHub"
    elif printf '%s' "$clean" | grep -q -E 'AGENTS\.md'; then
      room="desk"; label="Reading the map"
    else
      case "$tn" in
        mcp__*|*mcp*) label="Using an app" ;;
        WebFetch|WebSearch|read_url_content|search_web|browser_*) label="On the web" ;;
        Bash|run_command|exec_command|shell|PowerShell) label="Running a command" ;;
        *) label="Working" ;;
      esac
    fi ;;
  *) answer ;;
esac

# Who and since when: kept from the first report of this session
since="$now"; person=""
if [ -f "$file" ]; then
  since="$(cut -f2 "$file" | head -n 1)"
  person="$(cut -f4 "$file" | head -n 1)"
fi
[ -n "$person" ] || person="$(git config user.name 2>/dev/null)"
[ -n "$person" ] || person="Someone"

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$app" "$since" "$now" "$(safe "$person")" "$state" "$room" "$(safe "$target")" "$(safe "$label")" > "$file.$$" && mv "$file.$$" "$file"
remember "$person" "$label"
regen
answer
