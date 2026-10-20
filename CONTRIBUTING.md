# Contributing

This repo records my own judgement about agentic workflows on Android, so it
works a little differently from a typical open-source project.

## Issues: yes

Issues are the way to contribute. The most useful ones describe something
that **actually happened**:

- **What you ran**: the note or template, your setup (Claude Code version,
  Android Studio / AGP version, OS), and the command or prompt.
- **What happened**: output, error, or what the agent did.
- **What you expected.**

"It would be better if…" without a real run behind it is harder to act on.
It isn't banned, but an observed failure always wins.

## Pull requests: not for now

Pull requests from outside aren't accepted. If you've found a fix, put it in
an issue and I'll make the change. This may open up later.

## Scope

See [Scope in the README](README.md#scope). Issues outside it (Kotlin
Multiplatform, iOS, agents other than Claude Code, library how-tos) will be
closed with a pointer to why.

---

## How changes land

These rules apply to every change, including mine and any agent working on
my behalf. GitHub enforces the ones marked 🔒.

### Branches
- 🔒 `main` only changes through a pull request. No direct pushes, no
  force-pushes, no deleting it.
- Work on a branch named `<area>/<short-description>`, for example
  `secrets-hook/filename-matching`. Areas are listed below.
- Commits on a branch can be as messy as you like. Only the PR title and
  body reach `main`.

### Merging
- 🔒 **Squash merge only.** Each PR becomes one commit on `main`. The PR
  title becomes the commit subject, and the PR body becomes the commit
  message.

### PR titles (= commit subjects on `main`)

Format: **`area: outcome`**

```
secrets-hook: stop blocking androidx.credentials by matching filenames only
agent-loop: mark /verify as tested on a real project
setup-guide: correct the ktlint install step for Linux
```

- **Area** is where to look. One of:
  `readme` · `setup-guide` · `agent-loop` · `secrets-hook` · `ktlint-hook` ·
  `verify` · `reviewer` · `conventions` · `workflow` · `repo`
  (`repo` covers licence, settings, contributing and anything repo-wide.
  Add a new area when a new note or template arrives.)
- **Outcome** is what's now true, in the imperative, lowercase after the
  colon. Describe the behaviour, not the file: "Update README.md" says
  nothing that the diff doesn't.
- **A fix names the claim it corrects**, e.g. "correct the claim that…",
  "stop …". If something published was wrong, say so.
- 72 characters or fewer, no trailing full stop.

### PR bodies (= commit messages on `main`)

```
Why this change, in a few lines.

Verified: what was actually run, and the result
Not verified: what wasn't, said plainly
```

The **Verified / Not verified** lines are required on every PR. This repo
argues that an agent's "done" means nothing without proof, and the same goes
for its own history. "Not verified: nothing to run" is fine for a typo. A
missing line is not.

### Commit author and attribution

Everything in a commit is public forever, including its author line. History
on `main` can't be rewritten (force-pushes are blocked), so get this right
before the first commit on a new machine.

- **Use the GitHub noreply address, set per repo:**
  ```bash
  git config user.name  "Gurveer"
  git config user.email "17380838+gurveers@users.noreply.github.com"
  ```
  With no identity set, git makes one up from the machine, e.g.
  `name@Someones-MacBook-Pro.local`, which leaks the hostname.
  Check before committing: `git var GIT_AUTHOR_IDENT`.
- **No AI attribution lines.** No `Co-Authored-By:` trailers for AI agents
  and no "Generated with…" footers, in commits or PR bodies.

### Before opening a PR
- **Privacy scan.** No personal emails, real names other than the
  copyright line, home-directory paths, machine names, private project names
  or their domain terms, internal ADR numbers, or credentials. Grep the
  changed files for them; don't rely on reading.
- The status of anything you changed (in the note itself and in the README's
  "What's here" table) matches what was actually verified.
- Relative links resolve.
- Secrets hook changed → `bash templates/.claude/hooks/block-secrets.test.sh`
  passes.
- ktlint hook changed → `bash templates/.claude/hooks/ktlint-format.test.sh`
  passes.
- `/shape` check script changed → `bash templates/.claude/skills/shape/check-project.test.sh` passes.
- CI bar check changed → `bash templates/.github/scripts/check-bar.test.sh` passes.
- pre-push hook changed → `bash templates/.githooks/pre-push.test.sh` passes.
- `templates/.claude/settings.json` changed → `jq . templates/.claude/settings.json`
  parses.
