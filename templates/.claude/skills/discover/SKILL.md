---
name: discover
description: Find out what the user actually wants to build, and why, before any spec or code. Use when starting a new feature, app or change that isn't already fully described.
disable-model-invocation: true
---

Find out what the user actually wants, and why. Accuracy over speed: their
words first, your guesses last.

1. **Size it first.** If the request already says everything that matters,
   say so and stop. If it's a small change, ask a few questions and
   confirm in chat. Only a project gets the full process.

2. **Ask open questions, one per message.** Get them describing: "Walk me
   through the last time you needed this." No lists of options. Offer a
   guess only when they're stuck, and label it as yours.

3. **Look up facts yourself.** If the answer is in the code, the docs or
   the project, go and read it. Never ask the user for something you can
   find. Decisions are theirs; facts are yours.

4. **Push past answers that sound right.** "Scalable", "clean",
   "best practice", "the standard way" aren't goals. Ask: "If you didn't
   have to justify this to anyone, what would you actually want?"

5. **Stop when you can predict their answers to your next three
   questions.** Not before, and not long after.

6. **Restate, confirm, stop.**

   ```
   Outcome:      <one line>
   User:         <who it's for>
   Success:      <how we'll know it worked>
   Constraint:   <the binding limit>
   Out of scope: <what we're not building>
   ```

   Only an explicit "yes" confirms it. "Sounds good" and "whatever you
   think" don't count: ask what they'd change. Then stop and hand back to
   the user. Don't start the spec or any code. For a project, the next step
   is `/to-spec` in this same session: it turns this conversation into the
   spec issue, and nothing from discovery is saved anywhere else.

---
Adapted from `interview-me` ([addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), MIT)
and `brainstorming` ([obra/superpowers](https://github.com/obra/superpowers), MIT).
