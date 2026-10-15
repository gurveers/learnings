---
name: builder-check
description: Check that a spec can be built without asking its author. Use after a spec is written and before planning.
disable-model-invocation: true
---

Test whether an agent could build from this spec without talking to the
user.

1. **Send it to a fresh subagent** (general-purpose, none of this
   conversation) with this prompt, filling in the spec issue number:

   ```
   You are an experienced Android engineer. You've been handed a spec and
   asked to plan how to build it. You can't talk to the person who wrote it.

   Read the spec with `gh issue view <ISSUE> --comments`, and the project's
   CLAUDE.md files for conventions.

   Report only the questions you'd still need answered before you could plan
   this well: places where you'd have to guess and a wrong guess would
   matter. For each, give the question and why the answer changes the plan.
   Rank them by importance.

   Skip anything the spec leaves to the builder, anything you could
   reasonably decide yourself, and wording nitpicks. If nothing important
   is left, say "nothing important left".
   ```

2. **Sort what comes back:**
   - **Already answered** by the conversation or the code: add the answer
     to the spec.
   - **Minor:** a sensible builder could decide it without changing what
     gets built. Decide it, and mark it in the spec as your call.
   - **The user's:** only they can answer, and the answer changes what
     gets built. Ask these in one message, most important first.

3. **Update the spec issue** with the answers (`gh issue edit`), list the
   calls you made so the user can check them, and stop.

---
Adapted from the builder check in `brainstorming`
([obra/superpowers](https://github.com/obra/superpowers), MIT).
