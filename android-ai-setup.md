# AI-assisted Android development with Claude Code — setup guide

A reproducible setup for using [Claude Code](https://code.claude.com/docs/en/overview) as a day-to-day pair on Android/Kotlin projects. It is split into **what this setup already runs** (sections 1–7) and **what you should add on top** (section 8). Each config snippet is taken from a working machine, with project-specific details removed.

> Verified against Claude Code 2.1.278, Android CLI 1.0.16261425, Android Studio 2025.3 (JBR 21), ktlint 1.8.0, macOS on Apple Silicon — September 2026.

---

## 0. The mental model: configuration layers

Claude Code reads configuration in layers. The more specific layer wins, and `CLAUDE.md` files **add up** rather than replace each other:

```
~/.claude/                       ← YOU (every project on this machine)
├── CLAUDE.md                    how you want Claude to work with you
├── settings.json                default mode, global allowlist, status line
├── skills/                      Android skills (installed by `android skills`)
└── commands/                    your personal slash commands

<repo>/                          ← THE TEAM (committed, shared)
├── CLAUDE.md                    product + architecture context
├── .claude/settings.json        repo allowlist + hooks
├── .claude/hooks/*.sh           guardrails (secrets, formatting)
└── android/CLAUDE.md            module conventions, loaded when Claude works in android/

<repo>/.claude/settings.local.json  ← YOU, this repo only (gitignored)
```

**Rule of thumb:** personal preferences go in `~/.claude`. Anything a teammate also needs, such as conventions, guardrails and allowed build commands, gets committed into the repo.

Refs: [Settings & precedence](https://code.claude.com/docs/en/settings) · [How Claude remembers your project (CLAUDE.md)](https://code.claude.com/docs/en/memory)

---

## 1. Prerequisites: Android toolchain

1. **Android Studio**: install from the [Android Studio page](https://developer.android.com/studio) and let it install the SDK to `~/Library/Android/sdk`.
2. **Shell environment**: add this to `~/.zshrc`:

   ```bash
   # Use Android Studio's bundled JDK so terminal Gradle == IDE Gradle
   export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
   export PATH="$JAVA_HOME/bin:$PATH"
   export ANDROID_HOME="$HOME/Library/Android/sdk"
   export ANDROID_SDK_ROOT="$ANDROID_HOME"   # some tools still read the older name
   export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"
   ```

   **Why the bundled JBR instead of a standalone JDK:** Claude runs `./gradlew` from a terminal. If that terminal's JDK differs from Studio's, the two can give different build results and you lose time on the mismatch. The trade-off is that a Studio upgrade can silently change your JDK, and non-Android tools on the machine won't find a system JDK. Fix the first problem by declaring the toolchain in Gradle (see §8.2).

3. **CLI tools**: `brew install gh jq ktlint`. `gh` lets Claude read PRs and issues, `jq` is used by the hooks below, and ktlint powers the format hook.

Refs: [Java versions in Android builds](https://developer.android.com/build/jdks) · [Android environment variables](https://developer.android.com/tools/variables)

---

## 2. Install Claude Code

```bash
curl -fsSL https://claude.ai/install.sh | bash     # native installer
claude                                             # first run → log in
```

- **Terminal:** any terminal works. This setup uses [Ghostty](https://ghostty.org) with `"preferredNotifChannel": "ghostty"`, so you get a desktop notification when Claude needs you.
- **IDE:** install the [Claude Code plugin for JetBrains IDEs](https://plugins.jetbrains.com/plugin/27310-claude-code-beta-) in Android Studio. Claude can then see your open file and selection, and show diffs in the IDE's diff viewer. You still run `claude` from Studio's terminal.

Refs: [Quickstart](https://code.claude.com/docs/en/quickstart) · [Advanced setup](https://code.claude.com/docs/en/setup) · [JetBrains IDEs](https://code.claude.com/docs/en/jetbrains) · [Authentication](https://code.claude.com/docs/en/iam)

---

## 3. Global config: `~/.claude/settings.json`

```json
{
  "model": "opus[1m]",
  "permissions": {
    "defaultMode": "plan",
    "allow": [
      "Bash(git status)", "Bash(git diff)", "Bash(git diff *)",
      "Bash(git log)", "Bash(git log *)", "Bash(ls)",
      "Bash(gh pr list)", "Bash(gh pr view *)",
      "Bash(gh issue list)", "Bash(gh repo view *)"
    ]
  },
  "preferredNotifChannel": "ghostty",
  "statusLine": { "type": "command", "command": "bash ~/.claude/statusline.sh" }
}
```

Three deliberate choices:

| Setting | Why |
|---|---|
| `defaultMode: "plan"` | Every session starts read-only. Claude explores and writes a plan, and nothing changes until you approve it. This is the biggest improvement in the setup: you review the approach, and only then the diff. Press `Shift+Tab` to cycle modes when you want to skip planning. |
| Global allowlist = **read-only only** | Commands that only read state (`git diff`, `gh pr view`) never ask for permission. Anything that writes still does. Build commands are allowed per repo (§6.2), not globally. |
| `model: "opus[1m]"` | The strongest model with a 1M-token context, chosen for quality over quota. If you hit usage limits, move routine implementation to Sonnet with `/model` and keep Opus for design and review. |

### Status line

A small script turns the bottom bar into a live view of **folder · git branch · model · context % · weekly quota % · 5-hour quota %**, colored green below 60%, yellow up to 84%, and red from 85%. It reads `.model.display_name`, `.workspace.current_dir`, `.context_window.used_percentage`, `.rate_limits.seven_day.used_percentage` and `.rate_limits.five_hour.used_percentage` from the JSON Claude Code sends to the script on stdin. You can also ask Claude to build it for you: run `/statusline` and describe what you want.

Refs: [Configure permissions](https://code.claude.com/docs/en/permissions) · [Customize your status line](https://code.claude.com/docs/en/statusline) · [Manage costs](https://code.claude.com/docs/en/costs)

---

## 4. Global `CLAUDE.md`: how Claude should work with you

This file is loaded into every session. Use it for **how you like to work**, not for project facts. A trimmed template you can adapt:

```markdown
# Standing instructions — all projects

## Role
Act as a senior Android engineer and reviewer, not just a task executor.

## My context
Senior Android engineer. Calibrate pushback to that level.

## How to work with me
- Architecture/design decisions: ask me leading questions before giving your take.
- Mechanical work (installs, configs, routine fixes): just do it, explain as you go.
- Nontrivial decisions: surface the strongest alternative and a real critique unprompted.
- Trivial asks: short answers, no lecture.

## Working agreement
- Git: commit and push feature branches so work isn't lost. Never push to main,
  never force-push, never merge — PRs are mine.
- Verification: don't say something works unless you ran it. State what you
  verified vs. assumed.
- Scope: do what I asked. Refactors and "while I was in there" fixes get proposed, not performed.
```

The **working agreement** matters most. It turns "please be careful" into rules Claude can follow and you can check. The verification rule alone stops most "it should work now" answers.

**Auto-memory:** Claude also keeps per-project memories in `~/.claude/projects/<project>/memory/`, for example "JAVA_HOME points at the JBR on purpose; don't suggest switching." When you make a decision you don't want to re-argue, say "remember that…". Keep one fact per memory and include the *why*.

Refs: [How Claude remembers your project](https://code.claude.com/docs/en/memory) · [Best practices](https://code.claude.com/docs/en/best-practices)

---

## 5. Android CLI + official Android skills

Google's **`android` CLI** gives agents one interface to the SDK, emulators and devices, plus official docs. It also installs **Android skills**: packaged instructions Claude loads automatically when a task matches, such as migrating to Navigation 3 or upgrading AGP.

```bash
# Install (Apple Silicon — see the docs for Intel/Linux/Windows)
curl -fsSL https://dl.google.com/android/cli/latest/darwin_arm64/install.sh | bash
android init                        # sets up config dirs + default skills
android skills list                 # installed + available
android skills add --all --agent=claude-code   # or pick individually: android skills add navigation-3
android skills update               # refresh installed skills
android update                      # update the CLI itself
```

Skills land in `~/.claude/skills/<name>/SKILL.md`. Useful CLI commands for Claude to run:

| Command | Use |
|---|---|
| `android info` | SDK path, connected devices, env |
| `android docs …` | search and fetch official Android docs, which are more reliable than web search |
| `android describe` | project structure and build-output paths (APKs) |
| `android run` / `install` | build, deploy and launch on a device or emulator |
| `android emulator list/start` | manage AVDs |
| `android screen …` / `layout` | screenshots and UI tree, so Claude can check what it built |

The **24 skills** installed here, by what triggers them:

- **UI/Compose:** `adaptive`, `edge-to-edge`, `styles`, `navigation-3`, `navigation-event`, `migrate-xml-views-to-jetpack-compose`
- **Build/perf:** `agp-9-upgrade`, `r8-analyzer`, `android-profiler`, `testing-setup`
- **Security/policy:** `android-intent-security`, `play-policy-insights`
- **Identity:** `restore-credentials`, `verified-email`
- **Platform features:** `camerax`, `media3-cast-integration`, `appfunctions`, `ml-kit-genai-prompt-api`, `play-billing-library-version-upgrade`, `engage-sdk-integration`
- **Other form factors:** `wear-compose-m3`, `leanback-to-compose-tv-migration`, `display-glasses-with-jetpack-compose-glimmer`
- **Meta:** `android-cli`

Skills load on demand. Only the one-line description sits in context until a task matches, so installing all of them costs almost nothing. You can also call one directly, e.g. `/testing-setup`.

Refs: [Agent tools and resources](https://developer.android.com/tools/agents) · [Android CLI overview](https://developer.android.com/tools/agents/android-cli) · [Android skills overview](https://developer.android.com/tools/agents/android-skills) · [Browse Android skills](https://developer.android.com/tools/agents/android-skills/browse) · [android/skills on GitHub](https://github.com/android/skills) · [Claude Code skills](https://code.claude.com/docs/en/skills)

---

## 6. Project config (committed to the repo)

### 6.1 Layered `CLAUDE.md`

- **Root `CLAUDE.md`:** what the product is, the architecture in a few bullets, the list of key decisions (link your ADRs), and non-negotiables. `/init` generates a first draft that you then edit.
- **`android/CLAUDE.md`:** only the *module conventions*, so Claude writes code the way your team would review it. Don't repeat the root file. Example structure:

```markdown
# Android module — conventions
Applies to all code under `android/`. Complements the root CLAUDE.md.

## ViewModel vs UseCase
- ViewModel: owns UI state, maps domain → UI state, handles UI events. No business rules.
- UseCase: one business operation, no Android imports, plain-JUnit testable.
- The test: changes when the UI changes → ViewModel. Survives a UI rewrite → UseCase.
- Pure pass-through may go ViewModel → Repository. No ceremony UseCases.

## UI state
- StateFlow + collectAsStateWithLifecycle(). One immutable `XUiState` data class per screen.
- One-shot events (navigation, snackbar) go through Channel/SharedFlow — never into state.
- Immutable all the way down: `val` + read-only collections.

## Compose
- `XScreen(uiState, onEvent)` is stateless and previewable; a thin `XRoute()` wires the ViewModel.

## Modules
- By feature at the top (`:feature:foo`), layers inside; shared code in `:core:*`.
- Feature modules never depend on each other.

## Not yet decided — write an ADR when you hit these
- Error handling across layers, coroutine dispatcher conventions, testing stack.
```

The **"Not yet decided"** section is worth copying. It stops Claude from quietly choosing a convention for you.

### 6.2 Repo allowlist: `.claude/settings.json`

Allow the **safe, frequent** commands so Claude can build, test and inspect without asking each time. Leave anything that installs, uninstalls or writes to a device off the list.

```json
{
  "permissions": {
    "allow": [
      "Bash(git status)", "Bash(git diff *)", "Bash(git log *)", "Bash(git branch *)",
      "Bash(gh pr *)", "Bash(gh issue *)",
      "Bash(./gradlew tasks*)", "Bash(./gradlew test*)", "Bash(./gradlew lint*)",
      "Bash(./gradlew assembleDebug*)", "Bash(./gradlew :*:dependencies*)",
      "Bash(adb devices)", "Bash(adb logcat *)",
      "Bash(adb shell dumpsys *)", "Bash(adb shell pm list *)",
      "Bash(android info*)", "Bash(android emulator list*)",
      "Bash(android docs *)", "Bash(android describe*)"
    ]
  }
}
```

### 6.3 Secrets guard hook (PreToolUse)

`.gitignore` keeps secrets out of git, **not** out of Claude's context. This hook runs before every `Read`/`Edit`/`Write`/`Grep`/`Bash` call and denies any call that touches a file whose name looks like a secret.

`.claude/settings.json` (merge this with the allowlist above):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write|Grep|Bash",
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/block-secrets.sh\"" }
        ]
      }
    ]
  }
}
```

`.claude/hooks/block-secrets.sh`:

```bash
#!/bin/bash
# PreToolUse hook — blocks Claude from reading, writing, grepping or shelling
# out to secret-shaped files anywhere in this repo.
# Matching is anchored to the FILENAME, never a substring of the path.

input=$(cat)

# Secret-shaped basenames.
SECRET_RE='^\.env($|\.)|\.(pem|p12|jks|keystore)$|^(keystore|local)\.properties$|^google-services\.json$|^credentials\.json$|^service-account[^/]*\.json$'
# Committed placeholders — safe by construction; blocking them is pure friction.
ALLOW_RE='^\.env\.(example|sample|template|dist)$'

is_secret() {
  local name=${1##*/}                                   # basename
  [ -z "$name" ] && return 1
  printf '%s' "$name" | grep -qiE "$ALLOW_RE" && return 1
  printf '%s' "$name" | grep -qiE "$SECRET_RE"
}

deny() {
  local reason="Blocked by secrets guard: '$1' is a secret-shaped file. Handle secrets by hand, outside Claude Code."
  jq -n --arg reason "$reason" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')

if [ "$tool_name" = "Bash" ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
  # Split on whitespace and shell punctuation, strip quotes, test every token.
  while IFS= read -r tok; do
    tok=${tok//\"/}
    tok=${tok//\'/}
    [ -n "$tok" ] && is_secret "$tok" && deny "$tok"
  done < <(printf '%s\n' "$cmd" | tr ' \t\n|;&<>()$=,' '\n')
else
  # Read / Edit / Write carry file_path; Grep and Glob carry path.
  target=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')
  [ -n "$target" ] && is_secret "$target" && deny "$target"
fi

exit 0
```

**Lesson learned, which is why the matching is anchored to the filename:** an earlier version matched the bare word `credentials` anywhere in the path. That blocked `androidx.credentials`, the Credential Manager API, and any `CredentialsRepository.kt`. A deny rule blocks everything its pattern matches, so the pattern has to name exactly what you mean. Keep a regression test next to the hook and run it after every edit. You can test with fake payloads:

```bash
echo '{"tool_name":"Read","tool_input":{"file_path":"backend/.env"}}' | bash .claude/hooks/block-secrets.sh
# → {"hookSpecificOutput":{... "permissionDecision":"deny" ...}}
echo '{"tool_name":"Read","tool_input":{"file_path":"core/data/CredentialsRepository.kt"}}' | bash .claude/hooks/block-secrets.sh
# → (no output = allowed)
```

Note that this guards Claude's *tools*. It is not a sandbox. A determined `bash -c "$(echo …)"` can get around token matching, so keep real signing keys off the dev machine or in a password manager.

Refs: [Hooks guide](https://code.claude.com/docs/en/hooks-guide) · [Hooks reference](https://code.claude.com/docs/en/hooks)

---

## 7. Personal slash commands: reusable prompts

Any prompt you find yourself retyping can become a command. Put a Markdown file in `~/.claude/commands/` (personal) or `<repo>/.claude/commands/` (team), and it becomes `/<filename>`. (Newer Claude Code versions treat these as *skills*, and `.claude/skills/<name>/SKILL.md` is the fuller format. Both work.)

This setup uses a few **learning and review commands**. Two examples:

`~/.claude/commands/probe.md`: have Claude quiz you before you build something

```markdown
---
description: Socratic check on my understanding of a topic before I build
argument-hint: [topic or decision, e.g. "offline sync conflict resolution"]
allowed-tools: Read, Grep, Glob
disable-model-invocation: true
---

Probe my understanding of: $ARGUMENTS

You are examining me, not teaching me. Hold that line — the failure mode here is drifting into explanation after one or two questions.

Rules:

- **One question at a time.** Ask it, stop, wait for my answer. Never send a numbered list of questions.
- **Do not supply the answer**, not even partially, not even as a hint buried in the next question. If I'm stuck, ask a smaller question instead of helping.
- **Escalate.** Start where I probably am, then push toward the edges: failure modes, what breaks under load, what I'd have to give up, what I'd measure to know it's working.
- **Follow the weakness.** When an answer is vague, drill there rather than moving on. Vagueness is the signal — it's almost always covering the thing I haven't thought about.
- Calibrate to a Staff Engineer bar. "It works" is not an answer. "It works, here's what it costs, and here's when it stops working" is.

If the topic touches code in this repo, read it first so the questions are about my actual design rather than a generic version of it.

Stop after roughly 6–10 exchanges, or earlier if I'm clearly solid. Then give me:

1. What I actually understand
2. Where I was hand-waving — quote me back to myself
3. The one gap most likely to hurt me once I start building
4. Whether I'm ready to start. Plainly: yes or no.

Begin with your first question and nothing else. No preamble, no restating the topic, no explaining what you're about to do.
```

`~/.claude/commands/steelman.md`: challenge a decision after you make it

```markdown
---
description: Steelman the rejected alternative, then critique the chosen path at Staff bar
argument-hint: [decision, ADR number, or "the last thing we discussed"]
allowed-tools: Read, Grep, Glob
disable-model-invocation: true
---

Decision under review: $ARGUMENTS

If that names an ADR, read it. If it points at something from this conversation, use that. If it's ambiguous, ask me which decision I mean before going any further — do not guess and do not cover several at once.

Work through four sections, in order.

## 1. The decision as it stands

State it back in three sentences: what was chosen, what was rejected, and the reason given. If the stated reason doesn't actually support the conclusion, say so here rather than letting it slide.

## 2. Steelman the road not taken

Build the strongest honest case for the alternative I rejected. Strongest *honest* — not a strawman I can knock over, and not a position you can't support with real engineering reasons. Include the conditions under which that alternative is simply the better call.

## 3. The Staff-level critique

What would a Staff Engineer at Stripe push on in review? Bias toward what's cheap to ignore now and expensive later:

- What operational burden does this create, and who carries it at 3am?
- What does it cost — money, latency, build time, and the number of people who now have to understand it?
- Is this a one-way door? What's the migration path if it's wrong?
- What are we assuming about scale, load, or usage that nobody has measured?
- What's the failure mode nobody has considered, and how would we even notice it happening?

## 4. Verdict and tripwire

Does the decision survive? Say so plainly — don't hedge to seem balanced.

Then the part that matters most: **name the tripwire.** What specific, observable thing — a metric crossing a number, a requirement landing, a cost passing a threshold — should make me reopen this? A steelman with no "what would change my mind" is debate club, not engineering. Be concrete enough that I'd actually recognise it when it happens.

If the decision is genuinely right and the alternative genuinely weaker, say that too. Manufacturing doubt to appear rigorous is its own failure mode.
```

Two frontmatter fields do the safety work:

- `allowed-tools: Read, Grep, Glob`: the command can only read, so it can never edit code.
- `disable-model-invocation: true`: only **you** can trigger it. Claude won't decide on its own to quiz you.

Refs: [Extend Claude with skills (incl. custom commands)](https://code.claude.com/docs/en/skills)

---

## 8. Recommended additions (not yet in this setup)

Ordered by value for Android work. Items marked ✅ were tested on this machine while writing this guide. The rest are recommendations that haven't been run yet.

### 8.1 Kotlin language server plugin (highest value)

Without it, Claude finds things in Kotlin by text search. With it, Claude gets real go-to-definition, find-references and **compiler diagnostics after each edit**. On a large multi-module Android codebase that matters more than any prompt tweak.

```bash
brew install JetBrains/utils/kotlin-lsp
# then inside Claude Code:
/plugin      # → claude-plugins-official → kotlin-lsp → install
```

Refs: [kotlin-lsp plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/kotlin-lsp) · [Kotlin/kotlin-lsp](https://github.com/Kotlin/kotlin-lsp) · [Discover plugins](https://code.claude.com/docs/en/discover-plugins)

### 8.2 Pin the JDK in Gradle

Goes with the JBR choice in §1. Declare the JDK version in the build instead of inheriting whatever version Studio ships:

```kotlin
// build.gradle.kts of each module (or a convention plugin)
kotlin { jvmToolchain(21) }
```

Refs: [Java versions in Android builds](https://developer.android.com/build/jdks) · [Kotlin Gradle toolchains](https://kotlinlang.org/docs/gradle-configure-project.html)

### 8.3 ✅ Auto-format hook (PostToolUse, ktlint)

This hook runs ktlint after every edit Claude makes to a `.kt`/`.kts` file. It formats what it can, and **sends unfixable violations back to Claude** (exit code 2) so Claude fixes them in the same turn. Style problems never reach code review.

`.claude/hooks/ktlint-format.sh`:

```bash
#!/bin/bash
# PostToolUse hook — auto-format Kotlin files Claude just edited.
# Unfixable violations go back to Claude (exit 2 + stderr) so it fixes them itself.
f=$(jq -r '.tool_input.file_path // empty')
case "$f" in *.kt|*.kts) ;; *) exit 0 ;; esac
[ -f "$f" ] || exit 0
out=$(ktlint --format "$f" 2>&1) || { printf 'ktlint could not auto-fix %s:\n%s\n' "$f" "$out" >&2; exit 2; }
exit 0
```

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write",
        "hooks": [ { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/ktlint-format.sh\"" } ] }
    ]
  }
}
```

Tested with ktlint 1.8.0: badly spaced code was reformatted with exit 0, and a wildcard import (which ktlint can't auto-fix) produced exit 2 with the rule name on stderr. If your project already uses Spotless or ktfmt, call that instead so the hook and CI enforce the same rules.

Refs: [ktlint](https://github.com/ktlint/ktlint) · [Spotless](https://github.com/diffplug/spotless)

### 8.4 Keep the Android CLI and skills current

```bash
android update && android skills update
```

Google ships new skills and fixes often. This machine was one CLI version behind at the time of writing.

### 8.5 PR review in CI

Run `/install-github-app` inside Claude Code, or set up [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) yourself. Claude then reviews PRs, or implements changes when someone mentions `@claude` on an issue. It reads the same committed `CLAUDE.md`, so reviews follow your module conventions.

Refs: [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions)

### 8.6 MCP servers: add them only when a gap appears

This setup has **no MCP servers**, and that's deliberate. `gh` covers GitHub, and `android docs` covers Android documentation. Every MCP server adds tool definitions to your context and gives Claude one more place to act. Add one when you hit a specific gap, for example [`context7`](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/context7) for up-to-date third-party library docs, or `firebase` if you use it.

Refs: [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp)

### 8.7 Grow the allowlist from real usage

After a week of use, run `/fewer-permission-prompts`. It scans your sessions for read-only commands you keep approving and suggests allowlist entries. Add emulator and `android run` commands as your workflow settles.

---

## 9. Daily workflow

1. `cd` into the repo and run `claude`. It starts in **plan mode**.
2. Describe the task. Claude reads the code, asks questions, and writes a plan.
3. Review the plan. Reject it with a comment to change direction, or approve it to let Claude edit.
4. Claude implements the change and runs `./gradlew test`/`lint` (allowed without prompting). The hooks guard secrets and formatting.
5. Claude commits to a feature branch and pushes. **You** open and merge the PR.

Handy commands: `/model` (switch model), `/usage` (quota), `/context` (what's using your context window), `/clear` (fresh context between unrelated tasks), `/init` (draft a `CLAUDE.md`), `/plugin`, `/code-review`, and `! <cmd>` (run a shell command yourself; its output lands in the conversation).

Refs: [Common workflows](https://code.claude.com/docs/en/common-workflows) · [Best practices](https://code.claude.com/docs/en/best-practices)

---

## 10. Reference links

**Claude Code**
- Overview: https://code.claude.com/docs/en/overview
- Quickstart: https://code.claude.com/docs/en/quickstart
- Advanced setup: https://code.claude.com/docs/en/setup
- Settings & precedence: https://code.claude.com/docs/en/settings
- Permissions: https://code.claude.com/docs/en/permissions
- Memory / CLAUDE.md: https://code.claude.com/docs/en/memory
- Hooks guide: https://code.claude.com/docs/en/hooks-guide
- Hooks reference: https://code.claude.com/docs/en/hooks
- Skills & custom commands: https://code.claude.com/docs/en/skills
- Discover plugins: https://code.claude.com/docs/en/discover-plugins
- Create plugins: https://code.claude.com/docs/en/plugins
- MCP: https://code.claude.com/docs/en/mcp
- JetBrains IDEs: https://code.claude.com/docs/en/jetbrains
- GitHub Actions: https://code.claude.com/docs/en/github-actions
- Status line: https://code.claude.com/docs/en/statusline
- Common workflows: https://code.claude.com/docs/en/common-workflows
- Best practices: https://code.claude.com/docs/en/best-practices
- Manage costs: https://code.claude.com/docs/en/costs
- Official plugin marketplace: https://github.com/anthropics/claude-plugins-official
- JetBrains plugin: https://plugins.jetbrains.com/plugin/27310-claude-code-beta-
- GitHub Action: https://github.com/anthropics/claude-code-action

**Android**
- Agent tools and resources: https://developer.android.com/tools/agents
- Android CLI overview: https://developer.android.com/tools/agents/android-cli
- Android skills overview: https://developer.android.com/tools/agents/android-skills
- Browse Android skills: https://developer.android.com/tools/agents/android-skills/browse
- android/skills (GitHub): https://github.com/android/skills
- Java versions in Android builds: https://developer.android.com/build/jdks
- Environment variables: https://developer.android.com/tools/variables
- AI on Android: https://developer.android.com/ai

**Kotlin tooling**
- Kotlin LSP: https://github.com/Kotlin/kotlin-lsp
- Kotlin Gradle configuration (toolchains): https://kotlinlang.org/docs/gradle-configure-project.html
- ktlint: https://github.com/ktlint/ktlint
- Spotless: https://github.com/diffplug/spotless
