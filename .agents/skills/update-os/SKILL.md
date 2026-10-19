---
name: update-os
description: Installs a newer version of the AI OS template into this company's copy. Downloads the template, compares versions, shows what's new, replaces only template files the company never edited, asks about the rest, and never touches the company's context, team, automations, scripts or own skills. Admins only. Use when someone says "update the OS", "is there a new version", or "get the latest template".
---

# update-os

**Who:** admins only.
**Helper:** `.agents/skills/update-os/scripts/update-os.sh` (below it's called `UPD`). On a Mac or Linux run `sh UPD ...`. On Windows run it through Git's shell (AGENTS.md, section 8).

**Never touched by an update:** `context/`, `team.md`, `automations.md`, `scripts/`, `inbox/`, `.env`, `.env.example`, and any skill the company made. The helper refuses them. The company's sections in AGENTS.md and `.gitignore` (between the `company:...:start` and `:end` markers) are always carried over.

## 1. Get ready

1. Run `git status`. If there are unsaved changes, run **sync** first. Start from a clean state.
2. Make sure the template is set up as `upstream`: `git remote get-url upstream`. If it's missing, run `git remote add upstream <the "upstream" address in .os/manifest.json>`.
3. Run `git fetch upstream`.

## 2. Is there anything new?

Run `sh UPD check upstream/main`. It prints both version numbers, then one line per file that needs something.

If the versions are the same and nothing is listed, say "You're on the latest version" and stop.

## 3. Show what's new

Show the part of the new changelog between their version and the new one: `git show upstream/main:CHANGELOG.md`. Summarize it in plain words.

## 4. Explain the plan

Group the helper's list:

- **UPDATE**: the template changed it and the company never edited it. Safe to replace.
- **NEW**: a new template file.
- **REMOVE**: the template no longer has it, and the company never edited it.
- **REVIEW**: the company edited it **and** the template changed or dropped it. A person decides.
- **CLASH**: the new template has a file or skill with the same name as one the company made. A person decides. The company's version is never overwritten without a clear yes. Suggest renaming the company's skill with **create-skill**.
- **RUNS-BY-ITSELF**: the startup scripts and the like, which run by themselves on every teammate's computer. Show the full change (`sh UPD diff upstream/main <file>`), explain what it does in plain words, and get a **separate yes** for these. If anything looks like it sends data somewhere, downloads and runs something, or does more than the changelog says, say so and recommend not applying it.

## 5. Decide each REVIEW and CLASH

For each one, show both versions side by side (`sh UPD diff upstream/main <file>`) and explain the difference. Ask: keep ours, take the new one, or a merge of both. For a merge: run `apply`, then write the company's changes back in, and show the result.

## 6. Apply

After a yes to the plan:

- For each approved UPDATE, NEW or REVIEW: `sh UPD apply upstream/main <file>`
- For each approved REMOVE: `sh UPD remove upstream/main <file>`
- Then record the new version: `sh UPD finish upstream/main`

Then:

1. Refresh the skills for Claude Code: `sh .os/sync-skills.sh` (Windows: `.os\sync-skills.ps1`).
2. Check AGENTS.md still has the company's sections filled in.
3. Save and upload with **sync**, but commit with the update flag, because the safety check otherwise blocks changes to the startup scripts:
   ```bash
   AIOS_UPDATE=1 git commit -m "os-update: template <old> to <new>" -m "Why: <one line from the changelog>" -m "Asked by: <name>"
   ```
   In Windows PowerShell: `$env:AIOS_UPDATE='1'; git commit ...; Remove-Item Env:AIOS_UPDATE`
4. Tell everyone to start a new session, so their AI loads the new instructions.

If anything goes wrong halfway, `git restore .` puts back the files the update changed, and `git clean -n` lists any new files it added (delete those only after a yes). Nothing was uploaded yet.
