# Android conventions

How code in this project is written. Loaded automatically from `.claude/rules/`. The root `CLAUDE.md` holds the product context; don't duplicate it here.

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

## Coroutines and dispatchers
- **Main-safe by default.** The function that does blocking work owns the switch: `withContext(io)` inside it. Callers never switch dispatchers, so a new caller can't get it wrong.
- **Inject dispatchers**, don't hard-code `Dispatchers.IO`. Tests pass a test dispatcher.
- **No stored scopes in repositories or use cases.** Expose `suspend` functions or `Flow`s; the caller's scope (usually `viewModelScope`) owns the work and its cancellation.

## Testing
- **Stack:** JUnit4, Compose testing APIs, Robolectric for UI tests without a device, Compose Preview Screenshot Testing, Turbine for `Flow`s.
- **Fakes first.** A fake repository has behaviour (write, then read back; its `Flow` emits again), so the test checks the outcome. A mock only checks that a call happened. MockK only when a fake isn't possible.
- **Tests come from the spec.** Each acceptance criterion becomes a test, written and seen failing before the code. Expected values come from the spec, never recomputed the way the code computes them.

## Specs
- Acceptance criteria (on each ticket) for any UI change say **what the screen should show**: content, state, and the empty, loading and error cases. `/verify` takes a screenshot; this is what it checks against.

## Not yet decided — write an ADR when you hit these
Significant decisions get an ADR first. Open ones: error handling across layers (`Result`/sealed vs exceptions; whatever is chosen, never swallow `CancellationException`). Decide at the point of need, then record the outcome here.

## Revisit
Two calls above were close, and were flagged as such when adopted:
1. Allowing direct ViewModel → Repository for pure pass-through.
2. Preferring a data class over a sealed interface for UI state.

If either causes friction in practice, revisit the decision rather than working around it.
