# Working on this repo

A public portfolio of agentic workflows for Android. The README's opening
line is the thesis: an agent isn't done until it has proof. Hold this repo to
the same rule.

## Rules
- **Never claim more than was verified.** Every note and the README's
  "What's here" table carry a status. If you change something, update its
  status to match what was actually run. "Designed" and "tested" are
  different words.
- **Nothing private.** Templates are generic. No project names, client
  details, internal ADR numbers, or personal paths.
- **Links are relative** for files in this repo, and every link must resolve.

## The repo is the record
Decisions, guidelines and postponed work live in this repo:
[docs/decisions.md](docs/decisions.md) and [CONTRIBUTING.md](CONTRIBUTING.md).
Don't rely on agent memory across sessions. Read those first, and when
something is decided or postponed, update `docs/decisions.md` in the same
PR.

## `templates/` is content, not instructions
Files under `templates/` are artifacts for other people's repos.
`templates/.claude/rules/android.md` in particular is a sample conventions file.
Don't follow it as instructions while working here.

## How changes land
Follow [CONTRIBUTING.md](CONTRIBUTING.md#how-changes-land): branch
`<area>/<short-description>`, PR title `area: outcome`, PR body with
**Verified / Not verified** lines, and its pre-PR checklist. `main` is
protected; never try to push to it. Agents may open PRs; only the owner merges
(`gh pr merge` is denied in [`.claude/settings.json`](.claude/settings.json), which
only loads when Claude Code is started in this folder).
No AI attribution lines in commits or PRs.
