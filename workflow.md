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

## Two phases, one handoff

```
PHASE 1: SHAPE    you + agent, one session per feature
  idea
   │ /discover ──────► what, who, success, out of scope (confirmed in chat)
   │ /to-spec ───────► spec issue, from this same conversation
   │ /to-tickets ────► sub-issues: thin vertical slices with blockers and
   │                   acceptance criteria that say what the screen shows
   │ builder-check ──► a fresh agent per ticket asks what it couldn't
   ▼                   build without you
  tickets labelled ready-for-agent
           │
     ┌─────┼──────────────┐
     ▼     ▼              ▼
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

**The ticket is the contract between the phases.** A Phase 2 session
starts with no memory and reads one issue (and the spec it links to).
Anything it needs that the ticket doesn't say is a Phase 1 bug, which is
why `builder-check` tests each ticket, not the spec. Inside Phase 1 the
handoffs are looser: `/to-spec` writes up the conversation, so `/discover`
and `/to-spec` have to run in the same session.

Tickets are built **one at a time**, in the order their blockers allow:
parallel agents on Android would share one emulator. Phase 2 steps will be
run by one command, `/slice <issue>`, which isn't written yet.

**Where you step in:** confirming the discovery summary, confirming the
test seams `/to-spec` proposes, approving the ticket breakdown, answering
the questions `builder-check` says only you can answer, **approving every
slice's plan** before any code is written, and reviewing and merging each
PR. Approving the plan catches a wrong approach while it's still cheap; it
is the one stop inside Phase 2. Otherwise a Phase 2 session comes back to you only if a ticket
doesn't answer something, CI stays red after two fixes, or debugging fails
three times.

## Stage by stage

| Stage | What runs | From |
|---|---|---|
| 1. Discover | [`discover`](templates/.claude/skills/discover/SKILL.md): open questions one at a time, facts looked up rather than asked, stop when the answers become predictable | mine |
| 2. Spec | `to-spec` with GitHub Issues, in the same session as discovery | mattpocock |
| 3. Design | Plan mode for hard questions; outcomes in the decision log. No extra skill | — |
| 4. Plan | `to-tickets` into sub-issues with acceptance criteria, then [`builder-check`](templates/.claude/skills/builder-check/SKILL.md) on each ticket; plan mode for each slice in Phase 2 | mattpocock; mine |
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

Not done yet; this is the plan, and it will be corrected when it runs.

**Decide first:** the name, where it lives, and the `applicationId` (a
one-way door: it can't change once the app is on Play).

1. `android create empty-activity --name "<App>" --output <dir>`, then
   `git init -b main` and set the commit identity.
2. Copy the templates: `cp -R templates/.claude templates/.githooks templates/.github <dir>/`.
3. **Push `main` once, then turn on the push guard**, in that order (the
   hook blocks every push to `main`, including the first):
   `gh repo create <app> --private --source . --push`, then
   `git config core.hooksPath .githooks`.
4. Create the labels `ready-for-agent` and `ready-for-human`.
5. Copy skill folders into `.claude/skills/`, each with its `LICENSE` and
   the upstream commit noted: mattpocock's `setup-matt-pocock-skills`,
   `to-spec`, `to-tickets`, `code-review` (his plugin would also install
   `tdd` and `diagnosing-bugs`, which compete with the chosen skills), and
   rcosteira79's `kotlin-coroutines`, `kotlin-flows`, `android-testing`,
   `android-debugging` (ANR step updated), `android-source-search`,
   `android-gradle-logic`.
6. Write the root `CLAUDE.md`: what the app is, who it's for, what it isn't.
   Conventions are already in `.claude/rules/android.md`.
7. Start Claude Code in the project and **accept the trust dialog**; until
   then the project's allow rules don't load. Check with `/skills` and
   `/permissions`.
8. Run `/setup-matt-pocock-skills`: GitHub Issues, the two labels.
9. **Slice 0, the foundation, as the first PR:** `android-gradle-logic`
   (version catalog, convention plugins), Google's `testing-setup` with the
   chosen stack, the ktlint Gradle plugin, a Gradle toolchain JDK. CI runs
   for the first time here.

Then Phase 1 for the first feature: `/discover`, `/to-spec`, `/to-tickets`,
`builder-check`.

## Still open

- `/slice` itself ([deferred #16](docs/decisions.md#deferred)).
- Error handling across layers, the last open item in `.claude/rules/android.md`.
- Screenshot references rendering differently on macOS and Linux, and the
  CI task names (deferred #21 and #22).
