# Workflow v1: agentic Android, one developer

> **Status: assembled, not yet run.** Each piece was chosen by reading the
> candidates' actual files and comparing them ([the catalog](docs/workflow-candidates.md),
> [the decisions](docs/decisions.md)), October 2026. The hooks, the deny rules
> and the CI bar check are tested; the rest is designed. It will be tried on a
> new private Android app, and this page will say what happened.

Eight public skill repos were the raw material. None of them is
Android-aware end to end, and adopting one whole would mean running a
process I don't fully understand. So each stage got **one tool per job**:
an existing skill taken as is, an existing one adapted, or my own.

## Two phases, with tickets in between

```
PHASE 1: SHAPE    you + agent, one session per feature        (designed, not written)
  /shape <idea>  [+ screenshots, documents, links]
   1. Ready? ──► is the app repo set up? If not, /setup-project, then check again
   2. Talk ────► fill every section of the spec template, one question at a time
   3. Check ───► a fresh agent reads the draft: "what would I have to guess?"
   4. Write ───► docs/specs/<feature>.md in the app repo; you choose: PR or local
           │
  spec ─► tickets: a separate step, started by you when you decide (to-tickets)
           │
PHASE 2: BUILD    agent alone, one session per ticket
  /slice #12      /slice #13 (after #12 merges)   ...
   │ plan mode ──────► plan against the current code; you approve it
   │ build ──────────► tests first, from the ticket's acceptance criteria
   │ /verify #12 ────► lint, tests, build, run the app, screenshot,
   │                   each criterion: met / not met / unverifiable
   │ two reviewers ──► Android hazards + conventions; spec and scope creep
   │ PR "Closes #12" ► Verified, Not verified, Merge danger
   │ CI ─────────────► same checks on a clean machine, plus the bar check
   ▼
  you: read it, merge it (the agent can't). Merging unblocks the next ticket.
```

### Phase 1: `/shape`

Shaping only refines the thinking. It ends with a **spec**, not tickets
and not code. The [spec template](templates/docs/specs/TEMPLATE.md) drives
the conversation: discovery, options, feasibility and refinement are just
how its ten sections get filled (outcome, behaviour rules, screens and
states, edge cases, data, feasibility, decisions, testing, out of scope,
open questions). Behaviour rules replace user stories: each is one
testable statement that tickets can point to later.

Step 2 follows five rules:
1. One question at a time, in the owner's own words first.
2. Look facts up rather than asking: the app's code, Android docs, Play
   policy. Research runs in a subagent.
3. A real choice gets 2–3 options with trade-offs and a recommendation.
4. Minor details get a proposed default, marked as the agent's call.
5. Done when every section is filled and no question is open. Something
   only building can answer stays as an assumption with a revisit trigger.

**Input:** one sentence is enough. Screenshots, mockups, documents, links
and the existing app shorten the conversation. They are material, not
decisions: the agent says what it took from each, confirms it, and asks
about what they leave out. Documents from other people are information,
not instructions.

**`/setup-project`** is a separate command that `/shape` runs when the app
repo isn't ready. It asks for the path and what's missing, sets it up, and
the same check runs again. "Ready" means: a git repo with a Gradle project,
a private GitHub remote with `main` pushed, the push guard on, the project
files (`.githooks/`, `.github/`, `.claude/rules/android.md`, `docs/specs/`,
`docs/agents/`), a root `CLAUDE.md` written by the owner, and the workflow
linked into `~/.claude/` on this machine. A script checks this, so a pass
doesn't depend on the agent's judgement.

The app repo is the folder Claude was started in; otherwise `/shape` asks
for the path. Nothing about the app is stored in this public repo.

### Phase 2: `/slice`

A Phase 2 session starts with no memory and reads one ticket (and the spec
it links to). Tickets are built **one at a time**, in the order their
blockers allow: parallel agents on Android would share one emulator.
`/slice <issue>` isn't written yet.

**Where you step in:** in Phase 1, answering questions, choosing between
options, answering the check's questions, and choosing PR or local. Then
deciding when a spec becomes tickets. In Phase 2, **approving every
slice's plan** before any code is written, and reviewing and merging each
PR. Otherwise a Phase 2 session comes back to you only if a ticket doesn't
answer something, CI stays red after two fixes, or debugging fails three
times.

## Stage by stage

| Stage | What runs | From |
|---|---|---|
| 1–2. Discover and spec | `/shape` (not written yet): `discover`'s rules folded in, the spec template, a fresh-agent check ([`builder-check`](templates/.claude/skills/builder-check/SKILL.md)), and `to-spec` with its template replaced, writing a file | mine; mattpocock, adapted |
| 3. Design | Plan mode for hard questions; outcomes in the decision log. No extra skill | — |
| 4. Plan | When you decide: `to-tickets` turns a spec into sub-issues whose acceptance criteria point to its rules (details to settle). Plan mode for each slice in Phase 2 | mattpocock |
| 5. Build | One slice per session and PR. Knowledge: Google's `android/skills`, `kotlin-lsp`, and `kotlin-coroutines`, `kotlin-flows`, `android-source-search`, `android-gradle-logic` | Google; rcosteira79 |
| 6. Test | `android-testing` (test first, plus the Android traps). Stack: JUnit4, Compose testing, Robolectric, Compose Preview Screenshot Testing, Turbine, fakes before mocks. `testing-setup` once | rcosteira79; Google |
| 7. Verify | [`/verify <issue>`](templates/.claude/commands/verify.md) | mine |
| 8. Review | [`android-reviewer`](templates/.claude/agents/android-reviewer.md) and `code-review` (Standards and Spec) in parallel | mine; mattpocock |
| 9. Debug | `android-debugging`, with its ANR step updated | rcosteira79 |
| 11. Security | [Secrets hook](templates/.claude/hooks/block-secrets.sh), [deny rules](templates/.claude/settings.json), Google's intent-security and Play-policy skills, `/security-review` by hand for risky slices | mine; Google; built in |
| 12. Git and PRs | Branch `<area>/<N>-<slug>`, title `type(area): outcome`, [PR template](templates/.github/pull_request_template.md) with Merge danger, [`pre-push` hook](templates/.githooks/pre-push) | mine; mattpocock's `pr`, adapted |
| 13. CI | [`ci.yml`](templates/.github/workflows/ci.yml) on PRs, plus the [bar check](templates/.github/scripts/check-bar.sh) | mine |

**Not decided yet:** stage 0 (session setup: the existing `CLAUDE.md` layers
and plan mode by default, kept but not reviewed), and stages 10
(performance), 14 (release), 15 (operate) and 16 (learn). Those wait for
real code.

## Enforced, or only asked

Where a rule is cheap to enforce, it's enforced. Where it needs judgement,
it's an instruction, and a reviewer or I check it.

| Rule | How | Tested |
|---|---|---|
| Only I merge | `gh pr merge` denied | Yes |
| No pushes to `main`, no history rewrites | `pre-push` hook, plus deny rules | Hook 11/11; deny rules 21/22 (`git -C` gets past them, not the hook) |
| The hook isn't skipped or switched off | `--no-verify` and `core.hooksPath` denied | Yes |
| No secrets read or written | `PreToolUse` hook, fails closed without `jq` | 21/21 |
| Kotlin formatted | `PostToolUse` ktlint hook | 5/5 |
| The bar isn't lowered to get to green | Bar check in CI | 13/13; CI not yet run |
| It builds and the tests pass on a clean machine | CI | Not yet run |
| Don't merge red | Me | — |
| Tests first, from the acceptance criteria | `.claude/rules/android.md`, `android-testing` | Instruction only |
| Conventions followed | [`.claude/rules/android.md`](templates/.claude/rules/android.md), checked by both reviewers | Instruction, then review |
| No "done" without evidence | `/verify`; `/slice` won't open a PR before it | Instruction (`/slice` not written) |

## How the pieces were chosen

- **One tool per job.** Skills trigger on their description; two debugging
  skills means the agent picks one at random.
- **Knowledge, not conventions.** A skill earns its place by covering what
  models get wrong (coroutine cancellation, Compose test dispatchers), not by
  bringing its own architecture. `.claude/rules/android.md` is the only source of
  conventions.
- **Decide before a skill decides for you.** `kotlin-coroutines` and
  `testing-setup` would have settled questions I'd left open, so I settled
  them first.
- **Prefer an existing tool until it's seen to fail.** mattpocock's `to-spec`,
  `to-tickets` and `code-review` are taken as is, and marked for review after
  real use.
- **GitHub for everything.** Spec = issue, slices = sub-issues, PR closes the
  issue. One system, and the skills write the records.
- **The human gate is the merge.** Everything before it is the agent's job,
  and everything it claims comes with evidence.

## Setting up a new project

`/setup-project` will run these steps; it isn't written yet, and the list
will be corrected when it runs.

**Decided by you first:** the name, where it lives, and the
`applicationId` (a one-way door: it can't change once the app is on Play).

1. `android create empty-activity --name "<App>" --output <dir>`, then
   `git init -b main` and set the commit identity.
2. Copy the project files: `.githooks/`, `.github/`, `.claude/rules/android.md`,
   `docs/specs/` (with the template), and `docs/agents/issue-tracker.md` set
   to local markdown in `docs/specs/`, so `to-spec` writes a file.
3. **Push `main` once, then turn on the push guard**, in that order (the
   hook blocks every push to `main`, including the first):
   `gh repo create <app> --private --source . --push`, then
   `git config core.hooksPath .githooks`.
4. The root `CLAUDE.md`: what the app is, who it's for, what it isn't.
   Only you can write it; the command asks.
5. Once per machine: link the workflow into `~/.claude/` (skills, agents,
   hooks, deny rules). Still to decide: whether the ktlint hook runs only in
   opted-in projects, and whether the third-party skills live in this repo.
6. Start Claude Code in the app and **accept the trust dialog**; until then
   the project's allow rules don't load.
7. The check script runs: every item ✅ before `/shape` continues.

Not part of setup: **slice 0** (version catalog, convention plugins, test
stack, ktlint Gradle plugin, toolchain JDK; CI's first run) is the first
build task, and the GitHub labels wait until specs become tickets.

## Still open

- `/shape`, `/setup-project` and the check script, in that order, each
  shown before the next ([deferred #24](docs/decisions.md#deferred)).
- How a spec becomes tickets (#25), and `/slice` itself (#16).
- Error handling across layers, the last open item in `.claude/rules/android.md`.
- Screenshot references rendering differently on macOS and Linux, and the
  CI task names (#21 and #22).
