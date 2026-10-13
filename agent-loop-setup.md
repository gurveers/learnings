# Setting up an agent loop for Android

> **Status: designed, not yet run end to end.** These files have not been used on a real Android project yet. The secrets hook has a regression suite that passes (21/21), and the ktlint hook was tested on its own with ktlint 1.8.0.
>
> Checked against Claude Code 2.1.296, jq 1.7.1, ktlint 1.8.0 and Android CLI 1.0.16261425 on macOS, October 2026. The allowlist, `/verify` and the reviewer agent have never had a Gradle project to run against. I'll update this note once they have.

[android-ai-setup.md](android-ai-setup.md) covers installing and configuring Claude Code for Android. This note covers the next step: letting the agent **close the loop** by building, testing, running the app, looking at the screen, and reviewing its own diff before it tells you it's done.

All the files are in [`templates/`](templates/), laid out as they would be in a repo. Copy them in with:

```bash
cp -R templates/.claude templates/android <your-repo>/
```

## The loop

```
edit ──► ktlint hook formats it (PostToolUse)
  │
  ▼
/verify ──► ktlint ─► lint ─► unit tests ─► assembleDebug
  │                                             │
  │              UI changed? ──► android run ─► android screen ─► read the screenshot
  ▼
android-reviewer subagent ──► reads the diff against android/CLAUDE.md
  │
  ▼
you review a change that has already been built, run and looked at
```

## The pieces

### 1. An allowlist that covers the loop, plus a deny list ([`settings.json`](templates/.claude/settings.json))

The loop only works if Claude can run it without asking permission at every step. So the allowlist covers Gradle, `android run/screen/layout/install/emulator` and the read-only `adb` commands.

The **deny list** names the destructive device commands (`adb uninstall`, `adb shell rm`, `adb shell pm uninstall`, `android sdk remove`). Deny rules win over allow rules, so they stay blocked even if a broader allow rule is added later.

**Open question:** `Bash(./gradlew *)` is broad. It allows any task, including `publish` or a custom task that deletes files. The narrower option is to list the tasks one by one (`test*`, `lint*`, `assembleDebug*`). I haven't yet seen which tasks the loop actually needs, so this is a guess.

### 2. Formatting outside the review ([`ktlint-format.sh`](templates/.claude/hooks/ktlint-format.sh))

After every `.kt`/`.kts` edit, ktlint formats the file. Anything it can't fix goes back to Claude with exit code 2, so Claude fixes it in the same turn. Because of this, the reviewer agent is told **not** to flag formatting at all.

If ktlint isn't installed, the hook skips formatting rather than rejecting the edit. An earlier version sent back "command not found" as if it were a formatting error, on every Kotlin edit. A hook should never hand Claude a problem Claude can't fix. Its tests are in [`ktlint-format.test.sh`](templates/.claude/hooks/ktlint-format.test.sh).

### 3. A secrets guard ([`block-secrets.sh`](templates/.claude/hooks/block-secrets.sh) and its [test](templates/.claude/hooks/block-secrets.test.sh))

This is covered in the setup guide. The new part here is the regression suite. Run it after any change to the hook:

```bash
bash .claude/hooks/block-secrets.test.sh
```

### 4. `/verify`: no "it compiles, so it works" ([`verify.md`](templates/.claude/commands/verify.md))

This is a slash command that picks its checks from the diff, stops at the first failure, and reports each check as ran, passed, failed or skipped. A skip must say why. It never quietly counts a skip as a pass.

The step that matters is **visual verification**. If the diff touches a composable, Claude runs the app, takes a screenshot, *reads it*, and says whether the UI looks right. A green build tells you nothing about whether the screen is correct.

### 5. A reviewer that knows Android ([`android-reviewer.md`](templates/.claude/agents/android-reviewer.md))

A read-only subagent that reviews the diff against the project's own conventions file and checks for the runtime hazards that general code review misses:
- flows collected without lifecycle awareness
- a `Context` held in a ViewModel
- state that is lost on process death
- unstable Compose parameters
- one-shot events modelled as state

Three rules keep it useful:
- Every finding must name a **runtime consequence** (a leak, a dropped event, jank), not "violates convention".
- It has an explicit list of things **not** to flag (formatting, undecided questions).
- "This diff is clean" is a valid result. It must not make up findings to look useful.

### 6. The conventions it reviews against ([`android/CLAUDE.md`](templates/android/CLAUDE.md))

This is the module-level `CLAUDE.md` the reviewer reads first. Two of its calls were close, and the file says so:
- ViewModel → Repository directly for pure pass-through
- a data class rather than a sealed interface for UI state

Its **"Not yet decided"** section matters as much as the rules. It stops the agent from treating an open question as settled.

## What I expect to learn when it runs

- Whether `android screen` plus a model reading the screenshot catches real UI bugs, or just describes the screen.
- How slow the full `/verify` is on a real project, and whether that's slow enough that I stop running it.
- Whether the reviewer's "runtime consequence" rule keeps the noise down.
