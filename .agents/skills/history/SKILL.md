---
name: history
description: Answers questions about what changed in the company's AI OS - what changed this week, who changed a file and when, why something changed, and what a file used to say. Reads the git history and explains it in plain words. Never changes anything. Use when someone asks "what changed", "who changed the prices", "when did we add this skill", or wants an audit of changes.
---

# history

**Who:** everyone. This skill only reads; it never changes or restores anything.

Every change to the OS is saved in git with who, when, what and why. Use these to answer, then explain in plain words with dates. Don't show raw command output unless they ask.

| Question | Command |
|---|---|
| What changed recently? | `git log --since="1 week ago" --date=short --pretty=format:"%ad  %an  %s"` |
| Who changed a file, and when? | `git log --date=short --pretty=format:"%h  %ad  %an  %s" -- <file>` |
| What exactly changed? | `git show <id>` (the id is the short code from the list above) |
| When was a line or word added or removed? | `git log -S "<text>" --date=short --pretty=format:"%h  %ad  %an  %s"` |
| What did a file say on a date? | `git log -1 --before="<date>" --pretty=format:%h -- <file>`, then `git show <id>:<file>` |
| Who wrote each line of a file? | `git blame --date=short <file>` |

Run `git pull --ff-only` first, so the answer includes everyone's latest changes.

Good to know when you answer:
- The name on a change comes from that person's git settings. GitHub also records which GitHub account uploaded it. In a GitHub organization, that's the reliable record.
- Commit messages follow the format `<area>: <what changed>` with `Why:` and `Asked by:` lines (see the **sync** skill). Quote them.

**Bringing back an old version:** only an admin can do this, as a **new** change. Show the old text, and after a yes write it back into the file and run **sync** with the message `<area>: bring back <what> from <date>`. Never rewrite or delete history.
