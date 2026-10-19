<!--
Title: `type(area): outcome`, at most 72 characters. It becomes the squash commit on main.
  type: feat · fix · perf · refactor · test · build · ci · docs · chore
  area: the feature or module, e.g. settings, core-data
  e.g. `fix(settings): dark-mode toggle survives rotation`
Body sections are adapted from `pr` (mattpocock/skills, MIT), which credits
`show-me` (humanlayer/skills).
-->

Closes #

## Summary
<!-- The smallest picture that makes the point: a call tree, component tree,
     or file tree, as a `diff` when it shows what changed. Prose kept short. -->

## Verified
<!-- From `/verify <issue>`: each acceptance criterion, its evidence (a test
     name or a screenshot), and the result. Only what was run for this PR. -->

| Criterion | Evidence | Result |
|---|---|---|

## Not verified
<!-- Unverifiable criteria and skipped checks, each with the reason. "None" if none. -->

## Merge danger
**Door:** two-way <!-- or one-way: can't be undone by reverting -->
**Blast radius:** <!-- one word: what breaks if this is wrong -->

<!-- One-way doors on Android: Room migrations and DataStore schema changes,
     applicationId or signing, new manifest permissions or exported
     components, anything already released to Play. -->
