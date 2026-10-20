---
name: slice
description: Build one ticket of a private Android app, from issue to pull request - a plan the user approves, a test-first build, /verify, two reviewers, a PR and CI. Never merges.
argument-hint: "<issue number>"
disable-model-invocation: true
---

Build one ticket and hand back a pull request that has been planned,
tested, run, looked at and reviewed. The user approves the plan and merges
the PR; everything between is yours.

Run in a session started in the app repo, so its `CLAUDE.md`,
`.claude/rules/` and settings are loaded. If the current folder isn't the
app (no `settings.gradle(.kts)` or no `.claude/rules/android.md`), say so
and stop.

## 1. Ready?

Check all of these, and stop with the reason if any fails:
- the readiness check passes: `~/.claude/skills/shape/check-project.sh .`;
- the ticket is open and labelled `ready-for-agent` (`gh issue view <N> --comments`);
- every ticket blocking it is closed
  (`gh api repos/{owner}/{repo}/issues/<N>/dependencies/blocked_by`, or the
  `Blocked by:` line);
- the working tree is clean; then `git switch main && git pull --ff-only`.

Read the ticket, the spec it links (on `main`), `CLAUDE.md` and
`.claude/rules/android.md`.

## 2. Branch

`<area>/<N>-<short-slug>`, where the area is the feature or module, e.g.
`habits/11-reminder-time`.

## 3. Plan, and wait for approval

Enter plan mode and write a plan against the code as it is now:
- the approach, and the files or modules it touches;
- **for each acceptance criterion, the test that will prove it** (its name
  and where it sits);
- **the skills you'll use for this ticket** (for example `edge-to-edge`,
  `kotlin-flows`, `android-testing`), so a missing one shows up now;
- one-way doors: schema migrations, new permissions, manifest changes;
- anything you're leaving out because it isn't in the ticket.

Write no code until the user approves the plan.

## 4. Build, test first

For each acceptance criterion: write the test, run it, see it fail for the
right reason, write the least code that passes it, and run it again.
Commit after each criterion goes green. Follow `.claude/rules/android.md`.

Stop and ask the user if:
- the ticket doesn't answer something that changes what gets built (note
  it: shaping missed it);
- the same problem has survived three attempts at a fix. Use
  `android-debugging` before that, and report what you found.

Never make a check easier to pass instead of fixing the code: no new
`@Suppress`, `@Ignore`, baseline entries or re-recorded screenshots
without saying why in the PR.

## 5. Verify

Run `/verify <N>`. Every check must pass, and every criterion must be met
or marked unverifiable with a reason. Fix and run it again until it does.

## 6. Review

Run two fresh reviewers in parallel, each with none of this conversation:

- the `android-reviewer` agent, on `git diff main...HEAD`;
- a general-purpose agent with this prompt:

  ```
  Review this change against what was asked, not how it's written.
  Read ticket #<N> with `gh issue view <N> --comments`, and the spec it
  links. Read the change with `git diff main...HEAD`.

  Report:
  (a) acceptance criteria or spec rules for this ticket that are missing
      or only partly done;
  (b) behaviour in the change that nobody asked for;
  (c) anything that looks implemented but wrong.
  Quote the criterion or spec line for each. Under 300 words. If there's
  nothing, say "matches the ticket".
  ```

Show the two reports separately; don't merge or rank them. Check each
finding against the code before acting on it: fix it (with a test if it's
behaviour), or say why not. Findings you don't fix go in the PR. If you
changed code, run `/verify <N>` again.

## 7. Pull request

Push the branch (`git push -u origin <branch>`) and open the PR with
`gh pr create`:
- **title** `type(area): outcome`, at most 72 characters, e.g.
  `feat(habits): set and clear a reminder time`;
- **body** from `.github/pull_request_template.md`: `Closes #<N>`, a small
  Summary diagram, the Verified table from `/verify`, Not verified, Merge
  danger (one-way or two-way door, blast radius), and any review findings
  left unfixed with the reason.

## 8. CI

Wait with `gh pr checks <PR> --watch`. If it fails, read the log
(`gh run view <run> --log-failed`), fix the cause, push, and wait again: at
most two attempts, then stop and report. If the bar check fails, fix the
code, not the bar; if a bar change is genuinely needed, explain it in the
PR and leave it for the user.

## 9. Hand back

Report the PR link, the CI result, the criteria table, the merge danger
and anything the user should look at. Then stop. Merging is the user's.

---
The spec review is adapted from `code-review`
([mattpocock/skills](https://github.com/mattpocock/skills), MIT); checking
findings before acting on them, from `receiving-code-review`
([obra/superpowers](https://github.com/obra/superpowers), MIT).
