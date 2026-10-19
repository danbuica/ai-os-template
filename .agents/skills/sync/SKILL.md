---
name: sync
description: Saves and uploads finished changes to the company's AI OS on GitHub, and downloads everyone else's. Pulls first, commits with a clear message, pushes to main, and sorts out clashes with teammates' edits by asking which version to keep. Users only download. Use after every finished change to a skill, context, team.md or automations.md, or when someone says "sync", "save this", "upload" or "get the latest".
---

# sync

**Who:** everyone. **Admins** save and upload. **Users** only download (step 1). Check the role first (AGENTS.md, section 4).

Never force-push, never skip the safety check (`--no-verify`), never rewrite history, and never work on any branch but `main`.

## 1. Users: download only

Run `git pull --ff-only`.

- If it works, say "You're up to date" in one line.
- If it fails because there are local edits, explain that the files were changed on this computer. Users don't upload, so offer two choices: send the changes to the admins as a GitHub issue, or (with a clear yes) set them aside with `git stash`. Never delete their edits without asking.

## 2. Admins: check what's being saved

1. Run `git status` and `git diff`. List the changed files in plain words and confirm the work is **finished**. Never upload half-done work.
2. Read the changes for **personal data about real clients or people** (names, contact details, private facts). If you find any, stop and suggest a general version instead. The only exception is the five work details in `team.md`.
3. Stage only the files that belong to this change: `git add <files>`. Never stage `.env` or `inbox/`.
4. The safety check runs by itself when you commit and blocks keys, passwords, `.env`, inbox documents and changes to the startup scripts. If it says **STOPPED**, explain its message and fix the cause. Never get around it.

## 3. Commit with a clear message

Use this format, so the **history** skill can answer "who changed what and why":

```
<area>: <what changed, in plain words>

Why: <the reason, in one line>
Asked by: <name of the person who asked for it>
```

`<area>` is one of: `context`, `skill`, `team`, `automation`, `setup`, `os-update`. Example: `context: new 2027 prices in offer.md`.

## 4. Get teammates' changes first

Run `git pull --rebase`.

Git combines changes to **different parts** of a file by itself. It stops only when you and a teammate changed **the same lines**. Then:

1. Run `git status` to see which files clash.
2. In each file, the clash looks like this:
   ```
   <<<<<<< (the version already on GitHub: your teammate's)
   ...
   =======
   ...
   >>>>>>> (your new change)
   ```
   During this step the top half is the teammate's version and the bottom half is yours.
3. Show both versions side by side in plain words, and ask: keep theirs, keep yours, or a merge of both (write the merged text and show it).
4. Write the chosen text with the markers removed, then `git add <file>` and `git rebase --continue`.
5. If it gets confusing, `git rebase --abort` puts everything back as it was, with nothing lost. Explain, and ask how to go on.

## 5. Upload

Run `git push origin main`.

- If GitHub refuses because someone uploaded in the meantime, go back to step 4. Never force.
- If it refuses because of permissions, this person has read-only access on GitHub. Tell them an admin needs to give them write access, or that they're a user.

Then refresh the 3D explorer's data so its "Right now" line is current: `sh .os/build-explorer.sh --quiet` (on Windows through Git's shell, AGENTS.md section 8).

Finish with one line: what was uploaded.
