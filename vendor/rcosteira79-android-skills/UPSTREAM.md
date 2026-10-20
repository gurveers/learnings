# Vendored from rcosteira79/android-skills

Source: https://github.com/rcosteira79/android-skills, commit
`0f9af5ae88e7041cc3f901975237aedb1bd0edf6` (2026-09-19), path
`plugins/android-skills/skills/`. Licence: MIT, see [LICENSE](LICENSE).

Six of its skills, chosen in [docs/decisions.md](../../docs/decisions.md)
(stages 5, 6 and 9): `kotlin-coroutines`, `kotlin-flows`, `android-testing`,
`android-debugging`, `android-source-search`, `android-gradle-logic`. The
others carry conventions that compete with this workflow's own.

## Changes from upstream

- `android-debugging`: the ANR step used `adb pull /data/anr/traces.txt`,
  which a non-root device can't read; replaced with `adb bugreport`.

## Known dangling references

They point to skills not vendored here; the agent can't follow them.
- `kotlin-coroutines`, `kotlin-flows`: `android-skills:android-testing`
  (vendored, but without the plugin prefix).
- `android-debugging`: `android-skills:compose` and its
  `compose/references/performance.md`.
- `android-testing`: `compose/references/focus-navigation.md`.
- `kotlin-flows`: `compose/references/state-management.md`.
- `android-gradle-logic`: `gradle-build-performance`.

To check for upstream changes: compare these folders with the same paths at
the upstream repo's current `main`.
