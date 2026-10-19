---
name: os-guide
description: Explains what the company's AI OS is, lists the skills this person's role can use, and suggests a good next step. Use when someone asks what this is, what they can do, how it works, where to start, or seems lost.
---

# os-guide

**Who:** everyone.

1. **Find their role** (AGENTS.md, section 4): admin, user, or not in `team.md` yet. If `context/` doesn't exist, the OS isn't set up yet; skip to step 4.

2. **Explain the OS in a few plain sentences**, for example:
   > This folder is your company's AI operating system. It holds what the AI needs to know about the company (what you do, sell and how you talk) and skills: ready-made routines for common jobs. Everyone on the team shares it through GitHub, in Claude Code, Codex or Antigravity. Stable company rules live here; day-to-day notes about clients don't. They'll go in the company's second brain, coming later.

3. **List the skills they can use**, from the tables in AGENTS.md section 7 (the template's and the company's own), with one line each:
   - **Admin:** all of them.
   - **User:** the ones marked "everyone", plus **automate-process** (which sends their idea to the admins). Explain that if they want something changed, the AI will offer to send a request to the admins.
   - **Not in `team.md`:** only this guide. An admin needs to add them with **add-teammate**.

   Tell them they can also **see** the OS: open `explorer/index.html` (double-click it) for a 3D office of their skills, knowledge and team. Its **How to** tab has step-by-step guides with the exact commands to copy (installing, adding a teammate, automating a task and more), and **See it work** shows short scenes of how it works. If it looks out of date, run `sh .os/build-explorer.sh` first.

   Tell them how to start a skill: type `/` and its name in Claude Code or Antigravity, `$` and its name in Codex, or just ask in normal words.

4. **Suggest one next step**, the most useful one for them:
   - Not set up yet: an admin runs **setup-os**.
   - Admin, set up, but `automations.md` has no rows yet: **automate-process** on one repetitive task.
   - Admin with automations: **add-context** to add knowledge, or **history** to see recent changes.
   - User: ask what they're working on today and suggest the skill that fits.
