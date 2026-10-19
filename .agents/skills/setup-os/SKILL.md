---
name: setup-os
description: Sets up a brand-new AI OS for a company, once, with its first admin. Checks the repo is the company's own private copy, interviews the admin one question at a time, writes the context files, fills AGENTS.md, records the team, checks which apps can connect, and uploads everything. Use when the context/ folder doesn't exist yet or someone says "set up the OS".
---

# setup-os

**Who:** the company's first admin, once. Whoever runs this becomes the first admin.
**Needs:** git, the `gh` tool signed in (`gh auth login`), internet.
**Time:** about 30 to 45 minutes. Say so at the start.

Speak plain English. Ask **one question at a time** and wait for the answer. Before writing any file, show what you'll write and get a yes.

## 0. Before anything

- If `context/` already exists, the OS is already set up. Stop and suggest **add-context** (to add knowledge) or **update-os** (for a new template version).
- Check `git --version` and `gh auth status`. If either is missing, install it for them (ask first, and use the official installer for their system). If they're not signed in, run `gh auth login --web` and tell them to finish the sign-in in their browser. Never ask them to type commands themselves.
- Check `git config user.name` and `git config user.email` are set. If not, ask for their name and **work** email and set them with `git config --global`.

## a. Make sure this is the company's own private repo

Read the template's address from `"upstream"` in `.os/manifest.json`. Then run:

```bash
git remote -v
gh repo view --json nameWithOwner,visibility,isFork,parent,owner
gh api users/OWNER --jq .type      # "Organization" or "User"
```

It's fine only if **all** of these are true: `origin` is not the template's address, `visibility` is `PRIVATE`, and `isFork` is `false`. Otherwise explain the problem in plain words and fix it with them. Never change repo settings without a clear yes.

- **They cloned the template directly** (origin is the template). Run `git remote rename origin upstream`, ask where the new repo should live (their organization is best) and its name, then `gh repo create OWNER/NAME --private --source=. --remote=origin --push`.
- **It's a fork** (`isFork` is true). Forks of public repos are always public, so the company's knowledge must not go there.
  1. Run `git remote rename origin old-fork`.
  2. Create a new private repo as above.
  3. Run `git remote remove old-fork`.
  4. Tell them to delete the old public fork themselves on GitHub (Settings → Delete this repository). Don't do it for them.
- **It's their own repo but public.** Offer `gh repo edit --visibility private --accept-visibility-change-consequences`. Explain first: anyone who starred or watched it loses access.
- **All good.** Continue.

Then make sure the template is kept as `upstream` for future updates: `git remote get-url upstream`. If it's missing, run `git remote add upstream <the upstream address>`.

If the owner type is `User` (a personal account), explain: "On a personal account GitHub gives every invited person full write access, so the admin/user rule is only a polite check. A free GitHub organization fixes that." Don't block; let them choose.

## b. Interview

One question at a time. Accept short answers, and ask a follow-up only when an answer is too thin to be useful. Keep personal details about real customers out (for example, "small restaurants", not "Mario's Pizza on 5th street").

1. What's the company called, and what does it do, in a few sentences?
2. Who runs it, and roughly how big is the team? (Roles, not personal details.)
3. What do you sell? For each product or service: what it is, and what it costs.
4. Who are your customers? Describe the **types** (for example "small law firms, 5 to 20 people").
5. What problems do they come to you with, and why do they choose you?
6. How does the company talk? Formal or casual, words you like or avoid, and an example of a message you were happy with.
7. Which apps do you use, and for what? (Email, calendar, CRM, invoicing, chat, files...)
8. Anything the AI must always or never do? (Rules, promises, legal limits.)

Summarize what you heard in a few lines and ask whether it's right.

## c. More context (optional)

Offer the three ways from the **add-context** skill: links to read, documents dropped into `inbox/`, or a prompt to paste into another AI that knows them. If they want it, follow add-context's steps now (skip its final upload; step h does that).

## d. Write the context files

Use the templates in this skill's `assets/context/` folder. Create:

| File | Holds |
|---|---|
| `context/company.md` | what the company does, its story, team roles, always/never rules |
| `context/offer.md` | products and services with prices |
| `context/customers.md` | customer types, their problems, why they choose you |
| `context/voice.md` | how the company talks, with examples |
| `context/tools.md` | the apps it uses and what for |
| `context/processes/README.md` | from `assets/context/processes-README.md`; process descriptions go here later |

Leave out any section with no answer rather than inventing it. Then fill `AGENTS.md`, **only between the markers**:

- Between `company:about:start` and `company:about:end`: the company in **at most 5 lines** (name and what it does, what it sells, who for, how it talks, the main apps). Start the first line with the company name in bold, for example `**Copperline Bikes** is a mobile bike repair service...`. The 3D explorer reads the name from there.
- Between `company:routing:start` and `company:routing:end`: the table from `assets/routing-table.md`, with one row per context file you created.

Never edit AGENTS.md outside the markers. Updates replace everything outside them.

## e. The team

Ask for everyone who will use the OS, one person at a time: name, **work** email, GitHub username, and role (admin or user). The git email is optional: if they don't know it, use the work email (the role check matches people by GitHub username first). The person running setup is an admin; take their git email from `git config user.email`.

Write `team.md` from `assets/team.md`. Only those five details: nothing else about anyone. Offer to invite them on GitHub now with the **add-teammate** steps (the invite and the install message).

## f. Connect the apps

For each app from question 7:

1. Find out what's already connected in this tool:
   - Claude Code: run `claude mcp list`, and ask whether they've connected it under claude.ai → Settings → Connectors.
   - Codex: `codex mcp list`.
   - Antigravity: list the server **names** in `~/.gemini/config/mcp_config.json`. Never show the file's other contents, which can include keys.
2. Check whether an official connector or MCP server exists for that app (the app maker's own docs first, then the AI tool's connector directory). Prefer ones made by the app's own company.
3. Show a table: app, what's available, whether it's connected **for this admin right now**, and how to connect (steps for their tool, from the tool's current docs).
4. Write `context/tools.md` with what's available and how to connect, **not** who is connected. Connections are personal: each teammate connects the apps in their own AI tool.

Connect nothing without a yes. Keys go into `.env` or the tool's own settings, never into a file in this repo. If an app has no connector, say that **automate-process** can build a script for it later.

## g. Second brain

Mention in one sentence that day-to-day memory and notes about real people belong in a "second brain", which is coming in a later version, and not in this repo.

## h. Finish

1. Create `automations.md` from `assets/automations.md`.
2. Show the list of new files and run the **sync** skill to save and upload everything. Commit message: `setup: AI OS set up for <company>`.
3. Tell them what's next: teammates can now clone the repo, and **os-guide** shows everyone what they can do. Run `sh .os/build-explorer.sh` and suggest they open `explorer/index.html` to see their OS as a 3D office.
4. Offer to run **automate-process** on their first process: "What's one repetitive task that eats your time?"
