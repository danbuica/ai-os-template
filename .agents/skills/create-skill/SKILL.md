---
name: create-skill
description: Creates a new skill for this company's AI OS in the shared format that Claude Code, Codex and Antigravity all read. Writes it in .agents/skills, makes sure Claude Code sees it, lists what it needs (connectors, keys), adds it to AGENTS.md, tests it with the admin and uploads it. Admins only. Use when someone wants a new skill, or when automate-process needs one built.
---

# create-skill

**Who:** admins only. If the person is a user, offer to send their idea to the admins as a GitHub issue (AGENTS.md, section 4).

## 1. Agree what it does

Ask: what should the skill do, when should the AI use it, who may use it (everyone or admins), and what does "done" look like? Use one real example.

## 2. Name it

- Lowercase letters, numbers and hyphens only, at most 64 characters, not starting or ending with a hyphen, no double hyphens. For example `send-weekly-report`.
- It must not already exist in `.agents/skills/`.
- It must not be one of the template's own skill names: the `"skills"` list in `.os/manifest.json`. Those are reserved for the template's updates.
- Avoid names of the AI tools' own built-in commands (like `help`, `init`, `review`, `status`, `mcp`, `skills`, `hooks`, `plan`, `schedule`).

## 3. Write it

Create `.agents/skills/<name>/SKILL.md` from `assets/skill-template.md`:

- **Frontmatter:** only `name` (exactly the folder name) and `description`. The description says what the skill does **and when to use it**, in at most 1024 characters. It's what the AI reads to decide when to use the skill, so make it specific. Keep it short: the tools only show a limited amount of every description.
- **At the top of the body:** who may use it, and a **Needs** list: the connectors, MCP servers and keys it uses, and the AI tools it works in.
- **Steps:** plain, numbered, short. Under about 500 lines; put long reference material in a `references/` file inside the skill folder.
- If the skill makes files for people (reports, drafts, exports), it saves them in `outputs/<name>/`, with the date at the start of each file name. That folder is never uploaded (AGENTS.md, section 6).
- Templates and examples go in the skill's own `assets/` folder. API code goes in `scripts/<name>/` at the top of the repo, reading keys from `.env`. Add each key's **name** to `.env.example`, never its value.
- Never put secrets or personal data about real people in the skill.

## 4. Make every tool see it

- **Codex and Antigravity** read `.agents/skills` directly.
- **Claude Code** reads `.claude/skills`, which the startup check makes on each computer (a link on Mac and Linux, a copy on Windows). Refresh it now:
  - Mac or Linux: `sh .os/sync-skills.sh`
  - Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File .os\sync-skills.ps1`
- If the new skill doesn't show up, start a new session (in Claude Code you can also type `/reload-skills`).

## 5. List it in AGENTS.md

Add one row to the table between `company:skills:start` and `company:skills:end` in AGENTS.md: the name, who may use it, and one line on when to use it. Never edit outside the markers.

Then check that AGENTS.md is still short. If it's over about 200 lines, tell the admin and suggest trimming. Some tools cut off long instruction files.

## 6. Test it

Run it with the admin on the real example from step 1. Check the result together. Fix and test again until they're happy. Don't upload an untested skill.

## 7. Upload

Run the **sync** skill. Commit message: `skill: add <name> (<what it does in a few words>)`.
