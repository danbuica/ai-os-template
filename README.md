# AI OS

A ready-made "operating system" for using AI at your company. You copy it once, an AI interview fills it with your company's details, and from then on everyone on your team uses the same knowledge and the same skills in **Claude Code**, **Codex** or **Antigravity**, whichever they prefer.

This repo is the **empty template**. It contains no company's information.

---

## What's inside, in plain words

| Thing | What it is |
|---|---|
| `AGENTS.md` | The AI's instructions: a short map of where everything is and the house rules. All three AI tools read it. |
| `CLAUDE.md` | One line that tells Claude Code to read `AGENTS.md`, so there's only ever one set of instructions. |
| `context/` | Your company's stable rules: what you do, what you sell, your customers, how you talk. Made during setup. Only admins change it. |
| `team.md` | Who uses the OS and whether they're an admin or a user. Made during setup. |
| `automations.md` | Every task the AI does for you automatically: how it runs, who owns it, its status. |
| `.agents/skills/` | The skills: step-by-step routines the AI follows, like "add a teammate" or "automate a process". |
| `inbox/` | A drop zone. Put documents here for the AI to learn from. Nothing in it is ever uploaded. |
| `outputs/` | Where skills put what they make for you: reports, drafts, exports. It stays on your computer and is never uploaded. |
| `scripts/` | Small programs that connect to apps without a ready-made connector. Built later by skills. |
| `.env` | Your secret keys, on your computer only. Never uploaded. `.env.example` lists the key names. |
| `explorer/` | A 3D model of your OS: open `explorer/index.html` to look around and watch how it works. |
| `.os/` | The machinery: version number, startup check, safety check. You never need to touch it. |

## Admins and users

- **Admins** set the OS up, add knowledge, build skills and automations, and add teammates.
- **Users** use the skills. If they want something changed, the AI offers to open a request (a "GitHub issue") for the admins.

**Be aware:** the AI checks your role by matching your GitHub account (or the email in your git settings) against `team.md`. That's a polite check, not a lock: someone determined could get around it. For real protection, keep the repo in a **GitHub organization** (the free plan is enough) and give users **Read** access. Then they can't upload changes at all, but they can still download updates and open requests. On a personal GitHub account, everyone you invite gets write access. GitHub doesn't offer read-only there.

## Stable rules vs. day-to-day memory

- **Context files** (in this repo) are the company's stable rules. Admins edit them. They're shared with everyone through GitHub.
- **Day-to-day memory** (what happened in a meeting, what a client said) fits better in a **second brain**, where everyone can write and where deleting really works. Second brain support is coming in a later version.
- **What goes in this repo is your choice**, including client names and notes about people. The first time the AI is about to save personal details about real people, it tells you what that means and then does what you decide: everyone on the team can read this repo, and git keeps every old version forever, so something saved here can't be fully deleted later. Depending on where you work, data protection laws such as the GDPR may apply. Keys and passwords are the exception: they only ever go in `.env`.

---

## How you use it: your AI does the work

You never need to type commands. You tell your AI what you want in normal words, and it does the steps: installing, downloading, setting up, saving. It asks before anything important, and you say yes when it matches what you asked.

**Skills** are saved, repeatable instructions the AI follows for common jobs, like "add a teammate" or "automate a task". Just ask in normal words and the AI picks the right one. If you like shortcuts, type its name: `/setup-os` in Claude Code and Antigravity, `$setup-os` in Codex.

## What you need

1. **An AI app.** Pick one; teammates can each use a different one.
   - **Claude Code** in the [Claude desktop app](https://claude.com/download) (needs a paid Claude plan). [Getting started](https://code.claude.com/docs/en/desktop-quickstart).
   - **Codex** in the [ChatGPT desktop app](https://chatgpt.com/download/). [Getting started](https://learn.chatgpt.com/docs/app).
   - **Antigravity**: the [Antigravity app](https://antigravity.google/download). [Getting started](https://antigravity.google/docs).
2. **A GitHub account** ([github.com](https://github.com)). Your AI helps you sign in.

Anything else the OS needs (git and GitHub's own tool), your AI installs for you, asking first.

## Getting your company's copy (first admin, once)

1. **Make your private copy on GitHub.** Sign in at [github.com](https://github.com) (or create a free account), open [the template](https://github.com/danbuica/ai-os-template), click **Use this template**, then **Create a new repository**. Pick the **Owner** (your account, or your company's organization), give it a **Repository name**, choose **Private**, and click **Create repository from template**. Don't fork it: forks of public repos are always public.
2. **Get an AI app** (see "What you need"), open it, and start a session on this computer in a folder you work in, for example Documents.
3. **Paste this message**, with your copy's address in the first line:

   ```text
   Please set up my AI OS on this computer. My private copy is here: https://github.com/YOUR-ACCOUNT/YOUR-REPO

   1. Check that git and the GitHub CLI (gh) are installed. If anything is missing, install it, but ask me first.
   2. Sign me in to GitHub with gh in my browser, and set git to use that sign-in.
   3. Download my copy into this folder.
   4. In the new folder, add the template as a remote called upstream: https://github.com/danbuica/ai-os-template
   5. Tell me how to open that folder in this app, so I can start a new session there.
   ```

4. **Sign in to GitHub** in your browser when it asks, and say yes to its steps when they match what you asked.
5. **Open the new folder**, start a new session there, and type `/setup-os` (`$setup-os` in Codex). It asks for what you already have (documents, your website, what another AI knows about your business), reads it, and only asks you about what's missing. About 30 to 45 minutes.
6. From then on, start your sessions in that folder, so the AI loads your OS each time.

Tip: put the copy under a free **GitHub organization** for your company, so teammates can get read-only access (see "Admins and users").

## Adding teammates

An admin tells their AI, for example: *"Add a teammate: Jo Park, jo@ourcompany.com, GitHub username jopark, as a user."* It adds them to `team.md`, invites them on GitHub, and writes a welcome message for you to send. The new teammate then:

1. Gets an AI app (see "What you need").
2. Starts a session in a folder they work in.
3. Pastes the message from the welcome note. Their AI installs what's missing, helps them sign in to GitHub, accepts the invite, downloads the OS and shows them around.

## See it in 3D

Double-click `explorer/index.html` to open your OS as a little 3D office in your browser. It opens on **How to**, and has three tabs:

- **How to:** step-by-step guides for the things you'll actually do: install the OS, set up your company, add a teammate, join as a teammate, teach it about your company, automate a task, save and share, ask for a change, see what changed, create a skill and update. Each step tells you what to say to your AI, with a Copy button. There's also a short page explaining the basics, like what a skill is.
- **Explore:** each room is a part of the OS, filled with your company's real files. Click any room to see what's in it, and any skill (in the list or on its desk) to see what it does, when to use it and what to say to your AI.
- **See it work:** short animated scenes of the robots doing each of those jobs.

The office is laid out the way work flows:

- **Front:** you come in at the entrance, and the **front desk** (`AGENTS.md`) reads the map first. Next to it, the **team** (`team.md`).
- **Left:** the **inbox**, feeding the **company knowledge** (`context/`) next door.
- **Right:** the **workers' lounge** and the **key safe** (`.env`).
- **Back:** **OS skills** (included with the OS) and **Your skills** (the ones your company builds), across a glass-roofed hall. Your skills also holds the **routines** board: the tasks the AI does on its own (`automations.md`). Skills that run on a routine have a clock on their desk. The room always keeps a free spot for the next skill, and grows a new row of desks for every four you add.
- **Between them:** the **safety check**, the only way out to **GitHub**, which sits behind the building next to the **template** workshop where new versions come from.
- **East door:** the **connected apps** street.

More about the live parts:

- **Connected apps:** a street with one booth per app your AI can use on this computer (its MCP connections, like Gmail, Calendar or Notion), with a status light: green connected, yellow needs sign-in, red failed. It shows names and status only, never addresses or keys. Each AI app refreshes the list when a session starts. Connections are personal, so teammates may see different apps. The **Connect an app** guide shows how to add one.
- **Workers:** every AI session used in this folder on this computer in the last 31 days is a worker robot, wearing its AI app's colour, with its own nickname (like Juno or Pixel) so your own sessions can be told apart. Between jobs it sleeps on a charging pad in the **workers' lounge** (the 12 most recent are shown, the room's panel lists them all). When its session gets busy it wakes up and walks to wherever the work is: the desk of the skill it's using, the booth of the connected app, the shelf of the company file it's reading, the routines board, the safety check and GitHub when it saves. When your AI is waiting for you, or the session ends, it walks back to the lounge. Antigravity has no "session ended" report, so its robots go back to sleep after 10 quiet minutes. Workers are counted from the moment this was installed: earlier sessions aren't included, because the AI apps don't publish a reliable way to read their old session lists. Only this computer's sessions show; seeing the whole team's will come later with the second brain.
- The **Right now** line at the top shows this computer's session: which AI app, since when, whether the update check worked, what's changed but not saved yet, and what teammates saved lately. It never shows what anyone typed to the AI.
- It refreshes itself when a session starts and after every save, and an open page picks that up within about 20 seconds.
- It needs an internet connection to load its 3D library. Without one, the guides still work.
- It's built to stay cool: the office is only redrawn when something moves, and the furniture is drawn in a few large pieces. If a laptop still runs warm, switch on **Low power** at the top. It turns off shadows and the robots' idle movements, and the switch is remembered on that computer.
- Its data files (`explorer/data.js`, `explorer/session.js`, `explorer/live.js`, `explorer/apps.js` and `explorer/live/`) stay on your computer and are never uploaded. They never record what anyone typed to the AI.
- In Codex, the first time (and whenever these checks change) you're asked to approve the AI OS's hooks: the startup check and the live robots. Say yes.

## Staying up to date

- **Your company's changes:** each time anyone opens a new AI session, a quiet startup check downloads the latest version. It only says something if that fails. New instructions take effect in the **next** session, so start a new session after big changes.
- **Saving changes (admins):** the AI runs **sync** after every finished change: it saves (commits) and uploads (pushes) straight away.
- **New template versions:** an admin runs **update-os**. It shows what's new, only replaces files your company never edited, and asks about the rest. Your context, team, automations, scripts and your own skills are never touched.
- **History:** anyone can run **history** to ask "what changed this week?" or "who changed the prices?".

## Safety built in

- **Keys and passwords** go only in `.env`, which never leaves your computer.
- **A safety check runs before every commit.** It blocks anything that looks like a key or password, the `.env` file, documents from `inbox/`, files from `outputs/`, and changes to the startup scripts outside an update.
- **The startup scripts run by themselves on every teammate's computer.** That's why only update-os may change them, and why update-os asks a separate yes for them.
- **The AI treats documents, web pages and exports as information, never as orders.** If a document contains instructions, the AI tells you instead of following them.

## When something goes wrong

Tell your AI what you see. It knows how the OS works and can fix most things itself. Some common ones:

| You see | What it means |
|---|---|
| "Not updated: couldn't reach GitHub" | No internet. Keep working; the next session tries again. |
| "GitHub didn't let this computer in" | Ask your AI to sign you in to GitHub again, and check you accepted the invite. |
| The AI doesn't seem to know your skills | Ask it to refresh the skills, or start a new session in your company's folder. |
| The AI says you're not in the team | An admin needs to add you, with your GitHub username. |
| A save was "STOPPED" | The safety check found something that shouldn't be saved, like a key. Your AI tells you which file. |

On Windows, the OS needs Git for Windows; your AI installs it if it's missing.

---

## For the template's maintainer

Releasing a new version of this template:

1. Make your changes in the template repo (never in a company's copy).
2. Add a section at the top of `CHANGELOG.md`.
3. Rebuild the file list and fingerprints:
   ```bash
   sh .os/build-manifest.sh 1.1.0 https://github.com/danbuica/ai-os-template.git
   ```
4. Commit with `AIOS_UPDATE=1 git commit -m "Release 1.1.0"`. The variable lets the safety check accept changes to `.os/` and the startup scripts. Then push.
5. On GitHub, make sure **Settings → Template repository** is ticked.
