# Android module — conventions

Applies to all code under `android/`. Complements the root `CLAUDE.md` (product and architecture). Don't duplicate that content here.

## ViewModel vs UseCase
- **ViewModel**: owns UI state, survives config change, maps domain models → UI state, handles UI events. No business rules.
- **UseCase**: one business operation, no Android imports, plain-JUnit testable. Single `operator fun invoke()`.
- **The test**: if it changes when the *UI* changes → ViewModel. If it would survive a full UI rewrite, or gets reused by another screen → UseCase.
- Pure pass-through (genuinely no logic) may go ViewModel → Repository directly. Don't add ceremony UseCases that only forward a call — the indirection costs more than it documents.

## UI state
- `StateFlow` + `collectAsStateWithLifecycle()`. Not LiveData — legacy in a Compose codebase.
- One immutable `data class XUiState` per screen, exposed as a single `StateFlow<XUiState>`.
- Sealed interface *only* when states are genuinely mutually exclusive. Default to the data class: sealed hierarchies force artificial exclusivity and end up duplicating shared fields across branches.
- One-shot events (navigation, snackbar) go through a separate `Channel`/`SharedFlow` — never into state. State is re-emitted on recomposition; events must fire exactly once.
- Immutable means immutable all the way down: `val` properties, and read-only collection types (`List`, not `MutableList`) in state and domain models. A `val` holding a mutable collection is still mutable state.

## Compose state hoisting
- A composable may own state that is purely presentational and disposable: scroll position, expanded/collapsed, focus, animation.
- Anything that affects business logic, must survive config/process death, or is read by more than one composable → hoisted to the ViewModel.
- **Screen pattern**: `XScreen(uiState, onEvent)` is stateless and previewable; a thin `XRoute()` wrapper does the ViewModel wiring. Previews and UI tests then need no ViewModel to render.

## Module structure
- **By feature at the top level, layers inside**: `:feature:settings` holds its own ui/domain/data. Shared code lives in `:core:ui`, `:core:model`, `:core:data`, `:core:testing`.
- **Dependency rule**: feature modules never depend on each other — only on `:core:*`. Cross-feature navigation goes through the app-level nav graph.
- **Why not by-layer**: one top-level `:data` module becomes contended by every feature, kills build parallelism, and blurs ownership.

## Navigation
- Type-safe routes (serializable route types), defined in a centralized graph — not stringly-typed paths.
- Pass data **through the route**, not via shared/global state. Shared state between screens leaks across the back stack and makes deep links and process death restore incorrectly.
- Route definitions for a feature live with that feature; the app-level graph composes them (see Module structure).

## Not yet decided — write an ADR when you hit these
Significant decisions get an ADR first. Open ones: error handling across layers (`Result`/sealed vs exceptions), coroutine scope & dispatcher conventions, and the testing stack (MockK vs Mockito, Turbine, Robolectric vs instrumented). Decide at the point of need, then record the outcome here.

## Revisit
Two calls above were close, and were flagged as such when adopted:
1. Allowing direct ViewModel → Repository for pure pass-through.
2. Preferring a data class over a sealed interface for UI state.

If either causes friction in practice, revisit the decision rather than working around it.
