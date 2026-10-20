---
name: automate-process
description: Turns a repetitive business task into an automation. Maps the process with a template, checks what the current AI tool can do for each step (connectors, MCP servers, scripts, browser control, computer use, schedules), proposes two or three options in plain words with a recommendation, and builds only the one the person picks. Admins build; for users it prepares the request as a GitHub issue for the admins. Use when someone says "automate this", "can the AI do X for me every week", or describes a task that eats their time.
---

# automate-process

**Who:** everyone. Admins get the automation built. Users get the same analysis, sent to the admins as a request (step f). Check the role first (AGENTS.md, section 4).

Plain English throughout. One question at a time.

## a. Map the process

Fill the template in `assets/process-template.md` together: the process name, who does it, how often, each step today, which apps, inputs and outputs, time it takes, and what goes wrong. Ask for one real recent example; it's what you'll test with later.

- **Admin:** save it as `context/processes/<process-name>.md` (lowercase, hyphens).
- **User:** don't save a file. Keep it for the issue in step f.

## b. Check the options for each step

**Don't rely on memory for what the tools can do. They change often.**

1. Work out which AI tool you're running in (Claude Code, Codex or Antigravity) and on which computer system.
2. Look at what's connected right now: the MCP servers and connectors available in this session. In Claude Code you can also run `claude mcp list`, in Codex `codex mcp list`.
3. Read that tool's **current** official docs (links in `references/tool-docs.md`) for browser control, computer use and scheduling. Note the plan or system limits they mention.
4. For each step, check these options, in this order of preference:
   - **An existing connector** for the app. The most reliable.
   - **An MCP server** for the app, ideally official.
   - **A script in `scripts/`** that talks to the app's API, when there's no connector. Keys go in `.env`.
   - **Browser control** for websites with no API (whatever the current tool offers: Claude in Chrome, Codex's browser, Antigravity's browser...).
   - **Computer use** for desktop apps with no other way in.
   - **A schedule**, when it should run without anyone asking. Use what the current tool offers (in the cloud or on this computer) and note what each needs: some run only while the app is open and the computer is awake; cloud ones can't see this computer's files or `.env`.
5. Note which AI tools each option works in. Teammates may use a different tool, and something built on one tool's browser feature may not work in another.

## c. Propose two or three ways

Use `assets/proposal-template.md`. For each option, in plain words: what it does, setup time, cost, how reliable it is, what the person still does by hand, and which tools it works in. Then say which one you'd pick and why. Prefer the simplest thing that's reliable.

## d. Let them choose

They can pick one, mix them, or describe their own idea. **Build nothing before they agree.** If their idea won't work, say why kindly and suggest the nearest thing that will.

## e. Build it (admins)

1. Build the skill with the **create-skill** skill. API code goes in `scripts/<process-name>/`, and key names go in `.env.example` (names only, never values).
2. Ask them to put any keys in `.env` themselves, and explain how. Never paste keys into a file or into chat.
3. Set up the schedule, if any, using the current tool's own steps (from its docs), and show them where it lives.
4. **Test it on the real example from step a, with them watching.** Fix what's wrong and test again. Nothing goes live untested.
5. Add a row to `automations.md`: name, what it does, the skill or script, how it runs (by hand, or on a schedule and where), the tools it works in, the owner, status `testing` or `live`, and today's date.
6. Run the **sync** skill. Commit message: `automation: <name> (<how it runs>)`.

## f. Send the request (users)

Fill `assets/issue-template.md` with the process template from step a and the options from step c, including the one they chose. Then open it for the admins:

- With `gh`: `gh issue create --title "Automation request: <process name>" --body-file <temporary file>`. Delete the temporary file afterwards.
- Without `gh`: give them a link that opens a prefilled issue (`https://github.com/OWNER/REPO/issues/new?title=...&body=...`, text encoded for a web address). If the text is too long for a link, give the link with the title only and the text to paste in.

Tell them the admins will pick it up, and that **os-guide** shows what they can already use.
