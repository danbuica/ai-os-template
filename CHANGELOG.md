# Changelog

What changed in each version of the AI OS template. Newest first.
`update-os` shows the part between your version and the new one.

## 1.0.0 (2026-10-18)

First version.

- One set of instructions (`AGENTS.md`) and one set of skills (`.agents/skills`) for Claude Code, Codex and Antigravity.
- Skills: os-guide, setup-os, add-context, automate-process, create-skill, sync, history, add-teammate, update-os.
- A startup check in all three tools that downloads the latest version quietly and only speaks up when it fails.
- A safety check before every commit that blocks keys, passwords, `.env`, inbox documents, files from `outputs/` and changes to the startup scripts.
- An `outputs/` folder where skills save what they make for people (reports, drafts, exports). It stays on each computer and is never uploaded.
- Template updates that only replace files the company never edited and always keep the company's sections.
- A 3D explorer (`explorer/index.html`) that opens on step-by-step how-to guides (what to say to your AI, for Claude Code, Codex or Antigravity), shows the company's own OS as an office with clickable skills, plays short scenes of how it works, has a light "Right now" line for the current session and unsaved work, shows this computer's connected apps (MCP) as booths along a street, and shows every AI session used in this folder in the last month as a worker robot that rests in the workers' lounge and walks to the skill desk, app booth, shelf or place it's working on while its session is busy. The office is laid out the way work flows, and the Your skills room (with the routines board) grows as the company adds skills. It only redraws when something moves and has a Low power switch, so it stays cool on laptops.
