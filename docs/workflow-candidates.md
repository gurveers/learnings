# Workflow v1: candidates

**Status: draft for review.** Every skill, command and agent from eight public
skill repos, plus what's already on my machine, sorted by development stage.
Nothing here is chosen yet. We go through it stage by stage, pick **one tool
per job**, and the picks become `workflow.md`, workflow v1. That workflow is
then frozen and tried out on a new Android project.

Sources, checked October 2026:
[android/skills](https://github.com/android/skills) ·
[obra/superpowers](https://github.com/obra/superpowers) ·
[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) ·
[mattpocock/skills](https://github.com/mattpocock/skills) ·
[rcosteira79/android-skills](https://github.com/rcosteira79/android-skills) ·
[google/skills](https://github.com/google/skills) ·
[SimoneAvogadro/android-reverse-engineering-skill](https://github.com/SimoneAvogadro/android-reverse-engineering-skill) ·
[dpconde/claude-android-skill](https://github.com/dpconde/claude-android-skill)

**Key:** ✅ already have · ➕ candidate · ⚠️ overlaps or conflicts with something

## Rules for choosing

1. **One tool per job.** Skills trigger automatically. Two debugging skills
   means the agent picks one at random each time.
2. **Process and gaps, not conventions.** Add skills for *how to work*
   (debug, plan, test) and for *what the model gets wrong* (APIs). Don't add
   skills that bring their own architecture opinions. `android/CLAUDE.md` is
   the only source of conventions.
3. **How each one installs limits what you can pick.** superpowers installs
   as a whole plugin. addyosmani and mattpocock can be installed one skill at
   a time (`npx skills add … --skill <name>`). rcosteira79 is a plugin, or
   individual skill folders copied in.

---

## 0. Session and context

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | mine | Global `CLAUDE.md`, plan mode by default | Role, teaching style, git rules |
| ✅ | mine | Project `CLAUDE.md` layers | Product context + `android/CLAUDE.md` conventions |
| ➕ | addyosmani | `context-engineering` | Setting up rules files and context; what to do when output quality drops |
| ⚠️ | superpowers | `using-superpowers` | Forces a skill check before **any** reply. Conflicts with plan mode and Socratic flow |
| ⚠️ | addyosmani | `using-agent-skills` | Picks which skill applies (router) |
| ⚠️ | mattpocock | `ask-matt` | Router over his skills |

## 1. Idea and discovery

> **Decided 2026-10-15: my own [`discover`](../templates/.claude/skills/discover/SKILL.md) skill**, built from `interview-me` and `brainstorming`. Accuracy over speed: open questions before guesses. `/probe` isn't part of this stage (it tests understanding, not intent). Not yet used on a real project.

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | mine | `/probe` | Quizzes me before I build, one question at a time |
| ➕ | addyosmani | `idea-refine` | Diverge, then converge, on a vague idea |
| ➕ | addyosmani | `interview-me` | One question at a time until it's ~95% sure what I actually want |
| ➕ | mattpocock | `grilling` / `grill-me` | Relentless stress-test of a plan or idea |
| ⚠️ | superpowers | `brainstorming` | Mandatory before *any* creative work; drives toward a spec |
| ➕ | mattpocock | `prototype` | Throwaway prototype to answer one design question |
| ➕ | mattpocock | `research` | Researches primary sources, writes findings to a file in the repo |
| ✅ | product-management plugin | `product-brainstorming` | Thinking partner for product ideas |

## 2. Spec and requirements

> **Decided 2026-10-15, to revisit after real use:** mattpocock `to-spec` **as is**, with GitHub Issues as the tracker (the spec is an issue), then my own [`builder-check`](../templates/.claude/skills/builder-check/SKILL.md) step, plus a rule in [`android/CLAUDE.md`](../templates/android/CLAUDE.md) that acceptance criteria say what the screen shows. addyosmani's spec skill repeats project-level setup in every spec. `constraint-driven-development` is project-wide, so it moves to stage 13.

| | Source | Item | What it does |
|---|---|---|---|
| ➕ | addyosmani | `spec-driven-development` + `/spec` | Structured spec/PRD before code |
| ➕ | mattpocock | `to-spec` | Turns the conversation into a spec on the issue tracker (needs one-time setup) |
| ➕ | mattpocock | `grill-with-docs` | Grilling that writes ADRs and a glossary as it goes |
| ➕ | addyosmani | `constraint-driven-development` + `/constraints` | Writes the quality bar to `CONSTRAINTS.md` so agents can't quietly lower it |
| ✅ | product-management plugin | `write-spec` | Feature spec/PRD from a problem statement |

## 3. Design and architecture

> **Decided 2026-10-15: nothing new.** Feature design is recorded in the spec (stage 2), and `builder-check` finds the open questions. Challenging decisions is already the default from the global `CLAUDE.md`, with `/steelman` when I want it explicitly. Decisions go in `docs/decisions.md` or an ADR. **Revisit** if hard design questions keep coming up: mattpocock `grilling` is the first candidate.

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | mine | `/steelman`, `/sysdesign` | Strongest case for the other option; system-design interview |
| ✅ | engineering plugin | `architecture`, `system-design` | ADRs; designing systems and APIs |
| ➕ | mattpocock | `codebase-design` | Deep modules: where the seams go, making code testable and easy for agents to navigate |
| ➕ | mattpocock | `domain-modeling` | Glossary and domain terms, recorded with ADRs |
| ➕ | mattpocock | `improve-codebase-architecture` | Scans for improvements, HTML report, then grills one |
| ➕ | addyosmani | `api-and-interface-design` | Stable APIs and module boundaries |
| ➕ | addyosmani | `doubt-driven-development` | Every non-trivial decision gets an adversarial review in a fresh context |
| ⚠️ | rcosteira79 | `android-dev`, `modularization`, `android-data-layer` | Android architecture defaults. **Competing conventions** with `android/CLAUDE.md` |
| ✅ | android/skills | `adaptive`, `navigation-3` | Window sizes, multi-pane layouts, Navigation 3 |

## 4. Plan and break down

> **Decided 2026-10-15:** mattpocock `to-tickets` **as is**, so slices become **sub-issues** of the spec issue, with native blocking links. Each slice fits in one fresh agent session. How to build each slice is planned in **plan mode** right before building it, not written out up front.

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | built in | Plan mode, Plan agent | Plan before editing |
| ➕ | superpowers | `writing-plans` | Plan clear enough for "a junior with no context" |
| ➕ | addyosmani | `planning-and-task-breakdown` + `/planning` | Small tasks with acceptance criteria, in dependency order |
| ➕ | mattpocock | `to-tickets` | Tracer-bullet tickets with blocking links |
| ➕ | mattpocock | `wayfinder` | Work bigger than one session: a map of decision tickets |
| ✅ | product-management plugin | `sprint-planning` | Sprint scope and capacity |

## 5. Build

**Process**

| | Source | Item | What it does |
|---|---|---|---|
| ➕ | addyosmani | `incremental-implementation` + `/build` | Thin vertical slices: build, test, verify, commit |
| ➕ | superpowers | `executing-plans` | Carries out a plan inline |
| ➕ | superpowers | `subagent-driven-development` | A subagent per task, each reviewed |
| ➕ | superpowers | `dispatching-parallel-agents` | Independent tasks in parallel |
| ➕ | superpowers | `using-git-worktrees` | A separate workspace per feature |
| ➕ | mattpocock | `implement`, `implement-spec` | Builds from a spec or tickets |
| ➕ | addyosmani | `source-driven-development` | Every decision checked against official docs |

**Android knowledge**

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | android/skills | `android-cli`, `edge-to-edge`, `styles`, `navigation-event`, `camerax`, `media3-cast-integration`, `restore-credentials`, `verified-email`, `appfunctions`, `ml-kit-genai-prompt-api` | APIs where models perform poorly, written by Google |
| ✅ | mine | `kotlin-lsp` plugin | Go-to-definition and diagnostics for Kotlin |
| ➕ | rcosteira79 | `kotlin-coroutines`, `kotlin-flows` | Dispatchers, scopes, cancellation, collecting safely with the lifecycle |
| ⚠️ | rcosteira79 | `compose` | Compose patterns. Check against my conventions |
| ➕ | rcosteira79 | `datastore`, `paging`, `coil-compose`, `android-retrofit` | Library-specific traps (only if I use them) |
| ⚠️ | rcosteira79 | `koin` | A different DI library from Hilt. Pick one DI library first |
| ➕ | rcosteira79 | `android-source-search` | Fetches AOSP/AndroidX source when the docs aren't enough |
| ➕ | rcosteira79 | `android-gradle-logic` | Convention plugins, version catalogs |
| ➕ | dpconde | `generate_feature.py` | Feature-module generator (Now in Android style). Work in progress |
| ➕ | google | `firebase-basics`, `gemini-api` | Only if the app uses them |

## 6. Test

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | android/skills | `testing-setup` | Testing strategy: unit, UI, screenshot, end-to-end |
| ✅ | engineering plugin | `testing-strategy` | Test plans |
| ⚠️ | superpowers | `test-driven-development` | Strict red-green-refactor |
| ⚠️ | addyosmani | `test-driven-development` + `/test` | TDD, plus the "Prove-It" pattern for bugs |
| ⚠️ | mattpocock | `tdd` | TDD, noting what each test seam catches and misses |
| ➕ | rcosteira79 | `android-testing` | Android test specifics |
| ➕ | addyosmani | `test-engineer` agent | Test-strategy and coverage specialist |

## 7. Verify (before saying "done")

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | mine | `/verify` | Lint, test, build, **run the app, screenshot, read it**. Not yet tried on a real project |
| ✅ | built in | `run` skill | Launches the app to see a change working |
| ➕ | superpowers | `verification-before-completion` | No "done" claim without running checks |

## 8. Review

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | mine | `android-reviewer` agent | Android runtime hazards, measured against `android/CLAUDE.md` |
| ✅ | built in | `/code-review`, `/simplify` | Correctness review; clean-ups |
| ✅ | engineering plugin | `code-review` | Security, performance, correctness |
| ⚠️ | addyosmani | `code-review-and-quality` + `/review` + `code-reviewer` agent | Review across five areas |
| ⚠️ | mattpocock | `code-review` | Two checks: repo standards + matches the spec |
| ⚠️ | superpowers | `requesting-code-review` | Review at task boundaries |
| ➕ | superpowers | `receiving-code-review` | Checks feedback before acting on it, rather than blindly agreeing |
| ➕ | addyosmani | `code-simplification` + `/code-simplify` | Simplify without changing behaviour |
| ➕ | rcosteira79 | `android-ux` | Material 3 UX audit: touch targets, spacing, accessibility |

## 9. Debug

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | engineering plugin | `debug` | Reproduce, isolate, diagnose, fix |
| ⚠️ | superpowers | `systematic-debugging` | Root cause before proposing fixes |
| ⚠️ | addyosmani | `debugging-and-error-recovery` | Systematic root-cause debugging |
| ⚠️ | mattpocock | `diagnosing-bugs` | Diagnosis loop; proves a forced change actually landed before trusting a failing test |
| ➕ | rcosteira79 | `android-debugging` | Android-specific debugging |
| ✅ | android/skills | `android-profiler` | Traces, heap dumps, jank, startup |

## 10. Performance and build health

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | android/skills | `android-profiler`, `r8-analyzer` | Runtime profiling; R8 keep-rule cleanup |
| ➕ | rcosteira79 | `gradle-build-performance` | Build scans, configuration cache, kapt → KSP |
| ➕ | addyosmani | `performance-optimization` | General performance method (mostly web examples) |
| ✅ | engineering plugin | `tech-debt` | Finding and ranking tech debt |

## 11. Security and privacy

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | mine | Secrets hook | Blocks secret-shaped files. Tested |
| ✅ | built in | `/security-review` | Security review of pending changes |
| ✅ | android/skills | `android-intent-security`, `play-policy-insights` | Intent redirection and component exposure; Play policy and data safety |
| ➕ | addyosmani | `security-and-hardening` + `security-auditor` agent | OWASP-style hardening, threat modelling |
| ➕ | mattpocock | `git-guardrails-claude-code` | Hooks blocking `push`, `reset --hard`, `clean`, `branch -D` |
| ➕ | SimoneAvogadro | `android-reverse-engineering` | Decompile **my own** release APK: check what R8 strips and what endpoints or keys leak |

## 12. Git, PRs and shipping changes

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | mine | `learnings` conventions | `area: outcome`, Verified lines, squash-only, ruleset |
| ➕ | addyosmani | `git-workflow-and-versioning` | Atomic commits, splitting messy work, PR practice |
| ➕ | mattpocock | `pr` | Writing PR bodies |
| ➕ | superpowers | `finishing-a-development-branch` | Deciding how to integrate finished work |
| ➕ | mattpocock | `triage` | Moves issues through triage states into briefs an agent can act on |

## 13. CI/CD

| | Source | Item | What it does |
|---|---|---|---|
| ❌ | — | **Gap** | Nothing yet: "verified" means "on my machine" |
| ➕ | addyosmani | `ci-cd-and-automation` | Quality gates and test runners in CI |
| ➕ | built in | GitHub Actions (`/install-github-app`) | Claude reviews PRs in CI |
| ➕ | mattpocock | `setup-pre-commit` | Pre-commit hooks (Husky, for JS; the idea carries over) |

## 14. Release and launch

| | Source | Item | What it does |
|---|---|---|---|
| ➕ | addyosmani | `shipping-and-launch` + `/ship` | Pre-launch checklist from several specialist viewpoints, ending in go/no-go |
| ✅ | engineering plugin | `deploy-checklist` | Pre-deploy checks |
| ✅ | android/skills | `play-billing-library-version-upgrade`, `engage-sdk-integration` | Play-specific, if used |
| ➕ | google | `google-mobile-ads-*` | Only if the app has ads |

## 15. Operate and maintain

| | Source | Item | What it does |
|---|---|---|---|
| ➕ | addyosmani | `observability-and-instrumentation` | Logging, metrics, tracing, as evidence it works in production |
| ➕ | addyosmani | `deprecation-and-migration` | Retiring old code and migrating safely |
| ✅ | android/skills | `agp-9-upgrade`, `migrate-xml-views-to-jetpack-compose` | Android upgrades and migrations |
| ✅ | engineering plugin | `incident-response` | Triage and postmortems |

## 16. Learn and record

| | Source | Item | What it does |
|---|---|---|---|
| ✅ | mine | `docs/decisions.md`, `/ailog`, `/post` | Decision log, AI learning log, LinkedIn drafts |
| ➕ | addyosmani | `documentation-and-adrs` | ADRs and decision records |
| ➕ | mattpocock | `retro` | Retrospective on a coding session |
| ➕ | mattpocock | `handoff` | Condenses a session into a doc for the next agent |
| ➕ | mattpocock | `teach`, `wait-what` | Teaches a concept; "re-pitch that, it didn't land" |
| ➕ | mattpocock | `writing-fragments` → `writing-shape` | Raw notes → article (could feed `/post`) |
| ➕ | mattpocock | `writing-for-agents` | Writing skills and `CLAUDE.md` well |
| ➕ | superpowers | `writing-skills` | Creating and testing new skills |
| ✅ | engineering plugin | `standup`, `documentation` | Standup notes; technical docs |

---

## Left out, and why

| Items | Why |
|---|---|
| addyosmani `browser-testing-with-devtools`, `frontend-ui-engineering`, `web-performance-auditor`, `/webperf` | Web only |
| mattpocock `migrate-to-shoehorn`, `setup-ts-deep-modules`, `scaffold-exercises` | TypeScript or course tooling |
| mattpocock `chief-of-staff`, `claude-handoff`, `loop-me`, `wizard`, `to-questionnaire` | Experimental or not about development |
| superpowers `diagnosing-superpowers` | Only useful if superpowers is installed |
| rcosteira79 `kmp-boundaries`, `kmp-ktor` | KMP is out of scope |
| rcosteira79 `rxjava-migration`, `pdf-annotations` | Legacy migration; niche |
| android/skills TV, Wear, XR, glasses, Cast | Not this app's form factors (revisit if they become ones) |
| google Cloud, Ads (unless used), Rust | Not relevant to an Android app |
