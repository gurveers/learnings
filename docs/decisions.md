# Decisions

How this repo is set up and why, plus what's been deliberately postponed.
This file, not any agent's memory, is the record. Update it in the same PR
as the change it describes.

## Decided

| Date | Decision | Why |
|---|---|---|
| 2026-10-13 | **Notes and one tested plugin**, for two readers: people judging how I work, and developers who reuse the setup | Notes show the reasoning; an installable, evaluated plugin shows it ships |
| 2026-10-13 | **MIT licence** for notes and templates | Config and short hooks have no patent surface, so Apache-2.0 adds nothing; one licence keeps reuse simple |
| 2026-10-13 | **Title "Agentic Android"** with the thesis line under it; repo name unchanged for now | Matches the GitHub description; the repo name matters most in an install command, so it waits for the plugin |
| 2026-10-13 | **Status on everything**: each note and the README table says what was verified | The thesis is "no done without proof"; the repo has to meet its own bar |
| 2026-10-13 | **Scope: Android only, general agent lessons allowed**; no KMP/iOS, no agents other than Claude Code, no API how-tos | Focus; [android/skills](https://github.com/android/skills) covers API how-tos |
| 2026-10-13 | **Issues yes, pull requests no** | The repo records my own judgement; outside PRs would also be review work before there's content |
| 2026-10-13 | **`main` protected by a ruleset**: PR required, squash only, no force-push, no deletion, no bypass | Turns "never push to main" from an instruction to agents into something GitHub enforces |
| 2026-10-13 | **PR titles `area: outcome`**; fixes name the claim they correct | Nearly every change is docs, so a `docs:` type prefix would carry no information; area + outcome does |
| 2026-10-13 | **Verified / Not verified lines** in every PR body | Every change on `main` states what was proven |
| 2026-10-13 | **Noreply author email, no AI attribution lines** in commits and PRs | Author lines are public and permanent |
| 2026-10-13 | **Docs live in the repo**, not in agent memory | Anyone, human or agent, picks up the full context from the repo alone |

## Deferred

| # | Item | Waiting on |
|---|---|---|
| 1 | **Make it installable as a plugin.** Known constraints: a plugin can ship skills, agents and hooks, but **not** permission allow/deny rules, and a plugin's root `CLAUDE.md` isn't loaded (conventions would have to become a skill). `claude plugin eval` can test it with and without the plugin. Open questions: (a) what is the plugin's single job, and does the secrets hook belong in it? (b) are permission prompts for Gradle/`android` a flaw or the right default? (c) what should the reviewer do in a repo with no `android/CLAUDE.md`? | A decision on (a)–(c) |
| 2 | Skill anatomy (`SKILL.md` format, `references/`) | #1 |
| 3 | Rename the repo (e.g. `agentic-android`) | #1, since the install command is where the name shows |
| 4 | Add the `claude-code-plugin` topic | #1 existing |
| 5 | **Run the agent loop end to end** on a real Android project | A real project with a Gradle build |
| 6 | Tie each template to an observed failure. So far there's one: the secrets hook blocking `androidx.credentials` | #5 |
| 7 | Lifecycle diagram in README, philosophy section, evals, changelog/releases, attribution | Content from #5 |
| 8 | Link-check CI. Note: some docs sites return 200 for missing pages, so check titles, not only status codes | More notes, or a reported broken link |
| 9 | Narrow `Bash(./gradlew *)` in the template allowlist | Seeing which tasks the loop actually needs (#5) |
| 10 | Confirm the setup guide's "Used day to day" status in the README | Owner to confirm |
| 11 | Badges | Releases or stars to show |
| 12 | Homepage URL | A site to point to |
| 13 | `AGENTS.md` for other agents | Only if scope widens beyond Claude Code |
| 14 | Auto-delete merged branches; hide empty Wiki and Projects tabs | Owner to decide |
