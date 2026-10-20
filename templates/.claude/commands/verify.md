---
description: Build, test, lint and visually verify changed code before a commit or PR
argument-hint: "[issue number] [path]  (default: infer from the diff)"
---

Verify the current working state. Report only what you actually ran — never
claim a check passed without executing it.

## 1. Determine scope

If `$ARGUMENTS` includes an issue number, read it with
`gh issue view <number> --comments` and list its acceptance criteria. If
`$ARGUMENTS` names a path, verify that. Otherwise infer from `git status --short`
and `git diff --name-only HEAD`. If nothing changed, say so and stop.

Skip any section whose tooling isn't present yet (for example, no `gradlew`). Say it was skipped and why — don't silently pass.

## 2. Android checks

Run from the Gradle root, stopping at the first failure:

1. `./gradlew ktlintCheck` if configured, otherwise `ktlint --relative "**/*.kt"`
2. `./gradlew lintDebug`
3. `./gradlew testDebugUnitTest`
4. `./gradlew assembleDebug`

## 3. Visual verification — only if UI code changed

If the diff touches `@Composable` functions, screens, themes or layouts:

1. Confirm a device is available: `android emulator list` / `adb devices`
2. `android run` to build, install and launch
3. `android screen` to capture a screenshot
4. **Read the screenshot** and describe what's actually rendered
5. `android layout` and check the hierarchy matches the acceptance criteria
   (or, with no issue, the intent of the change)

State plainly whether the UI looks correct, wrong, or unverifiable. A build
that compiles is not evidence the UI is right — that's the whole point of
this step.

## 4. Acceptance criteria — only if an issue was given

For each criterion, one row:

| Criterion | Evidence | Result |
|---|---|---|
| <as written in the issue> | <test name, or "screenshot"> | met / not met / unverifiable |

Evidence is something you ran in this session. Tests passing is not evidence
for a criterion unless a test checks that criterion. **Unverifiable** needs a
reason (for example, needs a real network error, or no emulator available).
It doesn't block; it goes in the PR's **Not verified** line.

## 5. Report

Lead with failures. For each check state: ran / passed / failed / skipped, and
for skipped, why. Finish with a one-line verdict on whether this is safe to
commit. If anything failed, do not offer to commit — offer to fix.
