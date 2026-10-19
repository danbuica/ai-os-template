---
name: add-teammate
description: Adds a person to the company's AI OS - records them in team.md with their role, invites them to the GitHub repo with the right access, and writes the install steps to send them. Also removes people who leave. Admins only. Use when someone says "add a teammate", "give X access", "invite someone", or "remove X".
---

# add-teammate

**Who:** admins only. If a user asks, offer to open a GitHub issue for the admins (AGENTS.md, section 4).
**Needs:** the `gh` tool, signed in as someone who can manage the repo.

## Adding someone

1. **Ask, one at a time:** their name, **work** email, GitHub username, and role (admin or user). Explain the roles in one line each (AGENTS.md, section 4). Their git email is optional: if the admin doesn't know it, write the work email in that column. The role check matches people by GitHub username first. Ask nothing else about them.
2. **Check:** they aren't already in `team.md`, and the GitHub username exists (`gh api users/<username> --jq .login`).
3. **Add a row to `team.md`**: the five details only.
4. **Invite them on GitHub.** Find the owner type with `gh repo view --json owner --jq .owner.login`, then `gh api users/<owner> --jq .type`.
   - **Organization:** a user gets read-only access, an admin gets write access:
     ```bash
     gh api -X PUT repos/{owner}/{repo}/collaborators/<username> -f permission=pull   # user
     gh api -X PUT repos/{owner}/{repo}/collaborators/<username> -f permission=push   # admin
     ```
   - **Personal account:** GitHub gives every invited person write access there, whatever you ask for. Run the command without `-f permission=...`, and tell the admin plainly: this person *could* upload changes; only the AI's polite check stops them. A free GitHub organization fixes that.
   - GitHub sends them an invitation they must accept (by email or on github.com).
5. **The welcome message:** fill `assets/welcome-message.md` with their name, their role and the repo's page address (`gh repo view --json url --jq .url`). It tells them to paste one message into their AI, which does the rest. Give it to the admin to send. Don't send it yourself.
6. **Upload:** run the **sync** skill. Commit message: `team: add <name> as <role>`.

## Removing someone

1. Confirm who, and get a clear yes.
2. Remove their row from `team.md`.
3. Remove their GitHub access: `gh api -X DELETE repos/{owner}/{repo}/collaborators/<username>`. Removing someone with a pending invite: `gh api repos/{owner}/{repo}/invitations` lists invites, then `gh api -X DELETE repos/{owner}/{repo}/invitations/<id>`.
4. Mention that git keeps old versions of `team.md`, so their work details stay in the history. That's expected.
5. Run **sync**. Commit message: `team: remove <name>`.
6. Remind the admin to remove the person from any connected apps and shared keys too (and to change shared keys they had access to).
