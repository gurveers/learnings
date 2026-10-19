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

## One feature, start to finish

```
idea
 │ /discover ─────────────► what, who, success, out of scope (confirmed in chat)
 │ /to-spec ──────────────► spec issue, acceptance criteria say what the screen shows
 │ builder-check ─────────► a fresh agent asks what it couldn't build without me
 │ /to-tickets ───────────► sub-issues: thin vertical slices, ready-for-agent
 ▼
for each slice: one session, one branch, one PR
 │ plan mode ─────────────► plan against the current code
 │ build, test first ─────► tests come from the acceptance criteria
 │ /verify <issue> ───────► lint, tests, build, run the app, screenshot,
 │                          each criterion: met / not met / unverifiable
 │ two reviewers ─────────► Android hazards + conventions; spec and scope creep
 │ PR "Closes #N" ────────► Verified, Not verified, Merge danger
 │ CI ────────────────────► the same checks on a clean machine, plus the bar check
 ▼
me: read it, merge it (the agent can't)
```

The per-slice steps will be run by one command, `/slice <issue>`. It isn't
written yet.

## Stage by stage

| Stage | What runs | From |
|---|---|---|
| 1. Discover | [`discover`](templates/.claude/skills/discover/SKILL.md): open questions one at a time, facts looked up rather than asked, stop when the answers become predictable | mine |
| 2. Spec | `to-spec` with GitHub Issues, then [`builder-check`](templates/.claude/skills/builder-check/SKILL.md) | mattpocock; mine |
| 3. Design | Plan mode for hard questions; outcomes in the decision log. No extra skill | — |
| 4. Plan | `to-tickets` into sub-issues, then plan mode for each slice | mattpocock |
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
| Tests first, from the acceptance criteria | `android/CLAUDE.md`, `android-testing` | Instruction only |
| Conventions followed | [`android/CLAUDE.md`](templates/android/CLAUDE.md), checked by both reviewers | Instruction, then review |
| No "done" without evidence | `/verify`; `/slice` won't open a PR before it | Instruction (`/slice` not written) |

## How the pieces were chosen

- **One tool per job.** Skills trigger on their description; two debugging
  skills means the agent picks one at random.
- **Knowledge, not conventions.** A skill earns its place by covering what
  models get wrong (coroutine cancellation, Compose test dispatchers), not by
  bringing its own architecture. `android/CLAUDE.md` is the only source of
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

Not done yet; this list is the plan, and it will be corrected when it runs.

1. Copy the templates:
   `cp -R templates/.claude templates/.githooks templates/.github templates/android <your-repo>/`
2. Turn the push guard on in each clone: `git config core.hooksPath .githooks`.
3. Install mattpocock's `to-spec`, `to-tickets` and `code-review`, with
   GitHub Issues as the tracker and the labels `ready-for-agent` and
   `ready-for-human`.
4. Copy rcosteira79's `kotlin-coroutines`, `kotlin-flows`, `android-testing`,
   `android-debugging`, `android-source-search` and `android-gradle-logic`,
   with credit and the upstream commit noted.
5. Once, at creation: `android-gradle-logic` for the build setup and Google's
   `testing-setup` for the test stack.

## Still open

- `/slice` itself ([deferred #16](docs/decisions.md#deferred)).
- Error handling across layers, the last open item in `android/CLAUDE.md`.
- Screenshot references rendering differently on macOS and Linux, and the
  CI task names (deferred #21 and #22).
