#!/bin/sh
# Keeps the list of apps your AI can use on this computer (its MCP connections), for the 3D explorer.
# Only app NAMES and their status are kept: never addresses, keys or commands.
# Everything stays on this computer (explorer/live/ and explorer/apps.js are never uploaded).
#
#   sh .os/apps.sh refresh <claude|codex|antigravity>    update that AI app's list (each session start)
#   sh .os/apps.sh used <claude|codex|antigravity> <app>  note that a session just used an app
#   sh .os/apps.sh regen                                  rebuild explorer/apps.js

cmd="${1:-regen}"
ai="${2:-}"
root="$(cd "$(dirname "$0")/.." && pwd)" || exit 0
cd "$root" || exit 0
dir="explorer/live"
mkdir -p "$dir" 2>/dev/null || exit 0

# Antigravity expects a JSON answer from its hooks.
finish() { [ "$ai" = "antigravity" ] && [ "$cmd" = "refresh" ] && echo '{}'; exit 0; }

appid() { printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9'; }
# A friendly name: "claude.ai Google Drive" or "claude_ai_Google_Drive" -> "Google Drive", "plugin:x:y" -> "y"
nice() {
  printf '%s' "$1" | sed -E 's/^claude\.ai //; s/^claude_ai_//; s/^plugin[:_][^:_]+[:_](.+)$/\1/; s/_/ /g' |
    awk '{ if ($0 == tolower($0)) $0 = toupper(substr($0, 1, 1)) substr($0, 2); print }' | tr -d '\t"\\<>' | cut -c1-40
}
# Bundled helpers that aren't apps a person connected (ccd... are the Claude desktop app's own tools)
internal() { case "$(appid "$1")" in noderepl|cuarepl|codexapp|ccd*) return 0 ;; esac; return 1; }

# Prints the keys inside "mcpServers" of a JSON file.
json_servers() {
  awk '{ s = s $0 "\n" } END {
    n = length(s); depth = 0; instr = 0; buf = ""; last = ""; pend = 0; inside = 0; sd = -1
    for (i = 1; i <= n; i++) {
      c = substr(s, i, 1)
      if (instr) { if (c == "\\") { i++; continue } if (c == "\"") { instr = 0; last = buf; continue } buf = buf c; continue }
      if (c == "\"") { instr = 1; buf = ""; continue }
      if (c == ":") { if (inside && depth == sd) print last; if (last == "mcpServers") pend = 1; continue }
      if (c == "{") { depth++; if (pend) { sd = depth; inside = 1; pend = 0 } continue }
      if (c == "}") { if (inside && depth == sd) inside = 0; depth--; continue }
      if (c !~ /[ \t\n\r,]/) pend = 0
    }
  }' "$1" 2>/dev/null
}

write_list() { # stdin: raw<TAB>status lines -> explorer/live/apps-<ai>.txt as id<TAB>name<TAB>status
  out="$dir/apps-$ai.txt"
  : > "$out.$$"
  while IFS="$(printf '\t')" read -r raw st; do
    [ -n "$raw" ] || continue
    [ "$st" = "off" ] && continue
    internal "$raw" && continue
    id="$(appid "$(nice "$raw")")"
    [ -n "$id" ] || continue
    printf '%s\t%s\t%s\n' "$id" "$(nice "$raw")" "$st" >> "$out.$$"
  done
  mv "$out.$$" "$out"
}

regen() {
  now="$(date +%s)"
  {
    printf 'window.AIOS_APPS = { "updated": %s, "apps": [' "$now"
    # Merge every AI app's list with the "used" notes: one entry per app id
    for f in "$dir"/apps-claude.txt "$dir"/apps-codex.txt "$dir"/apps-antigravity.txt "$dir"/apps-used.txt; do
      [ -f "$f" ] && awk -F '\t' -v src="$(basename "$f" .txt)" '{ print src "\t" $0 }' "$f"
    done | awk -F '\t' '
      $1 == "apps-used" { id = $2; if (!(id in name)) name[id] = $3; used[id] = $5; usedBy[id] = $4; ids[id] = 1; next }
      { ai = $1; sub(/^apps-/, "", ai); id = $2; name[id] = $3; via[id] = via[id] (via[id] == "" ? "" : ",") "\"" ai "\":\"" $4 "\""; ids[id] = 1 }
      END {
        first = 1
        for (id in ids) {
          printf "%s\n  {\"id\":\"%s\",\"name\":\"%s\",\"via\":{%s},\"lastUsed\":%s,\"lastApp\":\"%s\"}", (first ? "" : ","), id, name[id], via[id], (used[id] == "" ? 0 : used[id]), usedBy[id]
          first = 0
        }
      }'
    printf '\n]};\n'
  } > "explorer/apps.js.$$" && mv "explorer/apps.js.$$" explorer/apps.js
}

case "$cmd" in
  refresh)
    case "$ai" in
      claude)
        # Claude Code's own list includes claude.ai connectors. It checks each connection, so it takes a few seconds.
        command -v claude >/dev/null 2>&1 || finish
        claude mcp list 2>/dev/null | awk -F ': ' 'NF > 1 {
          st = "connected"
          if (index($0, "✘")) st = "failed"
          else if (index($0, "Needs auth")) st = "needs sign-in"
          else if (index($0, "Pending approval")) st = "waiting for approval"
          else if (index($0, "⊘") || index($0, "Disabled")) st = "off"
          print $1 "\t" st
        }' | write_list ;;
      codex)
        for f in "${CODEX_HOME:-$HOME/.codex}/config.toml" ".codex/config.toml"; do
          [ -f "$f" ] || continue
          tr -d '\r' < "$f" | awk '
            function flush() { if (cur != "") print cur "\t" (off ? "off" : "set up"); cur = ""; off = 0 }
            /^\[mcp_servers\./ { s = $0; sub(/^\[mcp_servers\./, "", s); sub(/\].*$/, "", s); gsub(/"/, "", s); split(s, p, "."); if (p[1] != cur) { flush(); cur = p[1] } next }
            /^\[/ { flush(); next }
            cur != "" && /^[ \t]*enabled[ \t]*=[ \t]*false/ { off = 1 }
            END { flush() }'
        done | write_list ;;
      antigravity)
        for f in "$HOME/.gemini/config/mcp_config.json" ".agents/mcp_config.json" "$HOME"/.gemini/config/plugins/*/mcp_config.json; do
          [ -f "$f" ] || continue
          json_servers "$f" | awk '{ print $0 "\tset up" }'
        done | write_list ;;
      *) finish ;;
    esac
    regen ;;
  used)
    raw="${3:-}"
    [ -n "$raw" ] || finish
    internal "$raw" && finish
    name="$(nice "$raw")"; id="$(appid "$name")"
    [ -n "$id" ] || finish
    f="$dir/apps-used.txt"
    { [ -f "$f" ] && awk -F '\t' -v id="$id" '$1 != id' "$f"; printf '%s\t%s\t%s\t%s\n' "$id" "$name" "$ai" "$(date +%s)"; } > "$f.$$" && mv "$f.$$" "$f"
    regen
    printf '%s\t%s\n' "$id" "$name" ;;
  *) regen ;;
esac
finish
