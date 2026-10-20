# Agentic Android

**An agent isn't done until the app builds, the tests pass, and the change
has been checked against Android's real failure modes. These are the setups
that enforce that.**

> **Status:** work in progress. The setup is designed; the agent loop has not
> been run end to end on a real project yet. Each note says what has and
> hasn't been verified.

## What's here

| | What it is | Status |
|---|---|---|
| [Setup guide](android-ai-setup.md) | Configuring Claude Code for Android: toolchain, `CLAUDE.md` layers, permissions, a secrets hook, a ktlint hook, Android CLI and skills | Used day to day |
| [Agent loop](agent-loop-setup.md) | Letting the agent close the loop: build, test, run, and a reviewer that knows Android | Designed, not yet run end to end |
| [Workflow v1](workflow.md) | One feature from idea to merged PR: which skill runs at each stage, where it came from, and which rules are enforced rather than asked | Assembled, not yet run |
| [`templates/`](templates/) | The agent loop's files, laid out to copy into a repo | Both hooks tested (secrets 21/21, ktlint 7/7); git deny rules tested (21/22; the miss is `git -C`); pre-push hook tested (11/11); `/shape` readiness check tested (15/15); CI bar check tested (13/13), CI workflow not yet run; the rest untested |

## Start here

Read the [setup guide](android-ai-setup.md) first. The templates need
**Claude Code, `jq`, `ktlint` and the Android CLI** installed
(`brew install jq ktlint`; the guide covers the rest). To try the agent loop,
copy the templates into your project:

```bash
cp -R templates/.claude templates/.githooks templates/.github <your-repo>/
```

Read the files before you copy them. `settings.json` lets the agent run
Gradle and install to your device without asking, and the hooks are
guardrails, not a sandbox.

## Why this exists

There's a lot written about coding agents in general, and very little about
what actually happens when you point one at a Gradle project with real tests
and a real emulator. Android also has failure modes that general-purpose
agents don't check for: lifecycle, process death, recomposition, and what's
actually on screen.

I have been building Android apps for about fifteen years, most of that on
large consumer apps.

## Scope

**In scope**
- Agentic workflows for Android apps: setup, guardrails, verification, review.
- General lessons about working with coding agents, when they came out of
  Android work.

**Out of scope, for now**
- Kotlin Multiplatform and iOS.
- Agents other than Claude Code. The ideas may carry over; the files won't.
- API and library how-tos. [android/skills](https://github.com/android/skills)
  covers those; this repo is about whether the agent's work can be trusted.

## Built on

[Workflow v1](workflow.md) was assembled from public skill repos, one tool
per stage; its stage table says which piece came from where.

| Repo | Licence | Used for |
|---|---|---|
| [android/skills](https://github.com/android/skills) | Apache-2.0 | Installed as is: Android API skills, `android-cli`, `testing-setup` |
| [mattpocock/skills](https://github.com/mattpocock/skills) | MIT | Installed as is: `to-spec`, `to-tickets`, `code-review`. The PR template is adapted from `pr` |
| [rcosteira79/android-skills](https://github.com/rcosteira79/android-skills) | MIT | Six skills vendored in [`vendor/`](vendor/rcosteira79-android-skills/UPSTREAM.md) with their licence, pinned to a commit: coroutines, flows, testing, debugging, source search, Gradle logic |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | MIT | Adapted: `discover` (from `interview-me`) and the CI bar check |
| [obra/superpowers](https://github.com/obra/superpowers) | MIT | Adapted: `discover` (from `brainstorming`) and `builder-check` |

Also reviewed, not used yet: [google/skills](https://github.com/google/skills),
[SimoneAvogadro/android-reverse-engineering-skill](https://github.com/SimoneAvogadro/android-reverse-engineering-skill)
and [dpconde/claude-android-skill](https://github.com/dpconde/claude-android-skill).

## Feedback

Found something wrong, or tried a template and it broke? Open an issue and
say what you ran and what happened. Pull requests aren't accepted for now:
this repo records my own judgement, so changes come from issues. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE). This covers the notes and the templates. Third-party skills
keep their own licences.
