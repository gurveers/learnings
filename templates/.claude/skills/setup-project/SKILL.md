---
name: setup-project
description: Set up a private Android app repo for this workflow, or finish one that's partly set up. Use only when /shape's readiness check fails, or when the user asks to set up a project.
---

Get an app repo to the point where `check-project.sh` passes. Fix only what
the check says is missing; never overwrite or delete what's there.

**Plan mode.** Sessions may start in plan mode, which blocks writes. If
this one is, do the read-only steps there, and before the first fix in
step 3, ask to leave it (`ExitPlanMode`, saying what you're about to write
or create). The user approves the switch.

**Where things are.** This skill's folder is linked from the workflow repo.
Resolve its real path (`cd <this skill's folder> && pwd -P`); the project
files to copy are three levels up, in `templates/`. The check script is
`../shape/check-project.sh` next to this folder.

1. **Find the repo and check it.** Use the path `/shape` passed, otherwise
   ask for it. It must not be inside the workflow repo. Run
   `check-project.sh <path>` and show the result. If everything passes, say
   so and stop.

2. **For a new app, ask first**, in one message:
   - the app's name;
   - the `applicationId`, saying plainly that it can never change once the
     app is on Play;
   - whether the template's default `minSdk` is fine.

3. **Fix what failed, in this order**, skipping anything already passing:
   1. *Gradle project:* `android create empty-activity --name "<name>" --output <path>`,
      then `git init -b main`. If no commit identity is set, ask for one.
   2. *Project files:* copy `templates/.githooks/`, `templates/.github/` and
      `templates/.claude/rules/android.md` into the repo, and create
      `docs/specs/` and `docs/adr/`, each with a `.gitkeep`. Write `.claude/settings.json` with only
      the template's allow list
      (`jq '{permissions: {allow: .permissions.allow}}' templates/.claude/settings.json`):
      the hooks and deny rules are installed for the whole machine. If a file already exists, show the
      difference and ask; don't replace it.
   3. *`CLAUDE.md`:* ask the user, one question at a time, what the app is,
      who it's for, and what it isn't. Write their answers in their words.
      Anything they leave for later stays as a `TODO(owner):` line, and the
      check keeps failing until it's filled in.
   4. *First commit:* `git add -A && git commit -m "chore: project setup"`.
   5. *Private remote:* confirm the repo name, then
      `gh repo create <name> --private --source . --push`. This pushes `main`
      once, which has to happen before the push guard is on.
   6. *Push guard:* ask the user to run
      `! git -C <path> config core.hooksPath .githooks` themselves. Agents
      are denied that command so they can't switch the guard off; the same
      rule stops them switching it on.

4. **Check again** and show the result. If something still fails, say what
   and why, and stop. If everything passes, tell the user to start Claude
   Code in the app once and accept the trust dialog (the project's allow
   rules don't load until then), and hand back to `/shape`.

Not part of setup: slice 0 (version catalog, test stack, ktlint plugin,
toolchain JDK) is the first build task, and GitHub labels wait until specs
become tickets.
