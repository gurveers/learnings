---
name: tickets
description: Turn a finished spec in a private Android app into GitHub issues an agent can build one at a time. Run by hand after /shape; creates issues, writes no code.
argument-hint: "<path to docs/specs/<feature>.md>"
disable-model-invocation: true
---

Break a finished spec into tickets: thin vertical slices, each one a
self-contained brief that a fresh session with no memory can build. Then
publish them as GitHub issues. No code, and no changes to the repo.

Run every `gh` command from inside the app repo, so it targets that repo.

**Plan mode.** Sessions may start in plan mode, which blocks writes. If
this one is, do the read-only steps there, and before publishing in step
6, ask to leave it (`ExitPlanMode`, saying what you're about to write or
create). The user approves the switch.

## 1. Check the spec

The spec must be **final and on `main`**, because builder sessions read it
from the repo:
- `Status: final` in the file;
- after `git fetch`, `git cat-file -e origin/main:<path>` succeeds.

If either fails, say which and stop. A spec kept local needs its PR merged
first.

## 2. Draft the slices

Read the spec, the app's `CLAUDE.md` and `.claude/rules/`, and the code.

- **Each slice cuts through every layer** it needs (data, logic, UI,
  tests) and leaves something the user can see or a test can prove.
- **Each slice fits one fresh session**: small enough to plan, build,
  verify and review in one go.
- **Prefactoring comes first**, as its own slice, when it makes the rest
  easier.
- **Every behaviour rule, screen state and edge case in the spec is
  covered by exactly one slice.** List any that aren't, and fix that
  before going on.
- **Blocked by:** only the slices that genuinely have to land first.

**Slice 0, the foundation.** If the app has no `build-logic/` and no issue
labelled `foundation` exists (open or closed), add slice 0 first, blocking
every other slice: version catalog and convention plugins
(`android-gradle-logic`), the test stack from `.claude/rules/android.md`
(Google's `testing-setup`), the ktlint Gradle plugin, a Gradle toolchain
JDK, one example unit test and one screenshot test, and CI passing for the
first time (fix its task names if needed). Its choices are the app's first
decision records.

## 3. Agree the breakdown

Show the slices as a numbered list: title, what it delivers, what it
covers from the spec (rule numbers and sections), and what it's blocked by.
Ask whether the size feels right, whether the order is right, and whether
anything should be merged or split. Repeat until the user approves.

## 4. Write each ticket

```
## Spec
<link to the spec on main> · covers <R1, R3, §3 Edit screen, §4 reboot>

## What to build
<the behaviour, from the user's side; no file paths or code>

## Acceptance criteria
- [ ] <one checkable statement> (<R# or §#>)
- [ ] <for UI: what the screen shows, including empty, loading, error> (§3)
```

Criteria come from the spec; nothing new is decided here. If a criterion
needs a decision the spec doesn't have, it goes to the user in step 5.

## 5. Check each ticket

Send each draft to its own fresh general-purpose subagent, in parallel,
with none of this conversation:

```
You are an experienced Android engineer. You'll build this one ticket in
a fresh session; other tickets are built separately. You can't talk to
the person who wrote it.

<the ticket text>

The spec is at <path> in this repo; read it, and the app's CLAUDE.md and
.claude/rules/. Report only what you'd still have to guess before you
could plan this ticket well, where a wrong guess would matter: a
criterion you couldn't check with a test or a screenshot, a screen state
that isn't described, a boundary with another ticket that's unclear.
Rank them. If nothing important is left, say "nothing important left".
```

Answer from the spec or the code what you can; decide minor points and
mark them as the agent's call; ask the user the rest in one message.

## 6. Publish

1. Create any missing labels: `ready-for-agent`, `ready-for-human`,
   `foundation`.
2. Create the parent issue: the spec's title, its one-line outcome, and a
   link to the spec on `main`.
3. Create the tickets **in dependency order**, each as a sub-issue
   (`gh issue create --parent <parent>`), labelled `ready-for-agent`
   (slice 0 also `foundation`).
4. Add each blocking link with GitHub's issue dependencies:
   `gh api --method POST repos/<owner>/<repo>/issues/<ticket>/dependencies/blocked_by -F issue_id=<blocker's database id>`
   (the id from `gh api repos/<owner>/<repo>/issues/<n> --jq .id`). If that
   fails, put `Blocked by: #<n>` at the top of the ticket instead.
5. List what was created: number, title, blocked by.

Then stop. Building starts with `/build` on a ticket with no open blockers.

---
Adapted from `to-tickets` ([mattpocock/skills](https://github.com/mattpocock/skills), MIT)
and the builder check in `brainstorming` ([obra/superpowers](https://github.com/obra/superpowers), MIT).
