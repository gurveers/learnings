---
name: builder-check
description: Check that each ticket of a spec can be built without asking its author. Use after /to-tickets, as the last step before building.
disable-model-invocation: true
---

Test whether an agent could build each ticket without talking to the user.
The builder gets one ticket and nothing else from this conversation, so
that's what to test.

1. **List the tickets**: the sub-issues of the spec issue the user names.

2. **Send each ticket to its own fresh subagent** (general-purpose, none of
   this conversation), in parallel, with this prompt:

   ```
   You are an experienced Android engineer. You've been handed one ticket
   and asked to plan how to build it. You can't talk to the person who
   wrote it.

   Read the ticket with `gh issue view <TICKET> --comments`, the parent
   spec it links to, and the project's CLAUDE.md files for conventions.
   Build only this ticket; the others will be built separately.

   Report only the questions you'd still need answered before you could
   plan this well: places where you'd have to guess and a wrong guess would
   matter. Include acceptance criteria you couldn't check from a test or a
   screenshot, and screens whose empty, loading or error state isn't
   described. For each, give the question and why the answer changes the
   plan. Rank them by importance.

   Skip anything the ticket leaves to the builder, anything you could
   reasonably decide yourself, and wording nitpicks. If nothing important
   is left, say "nothing important left".
   ```

3. **Sort what comes back**, across all tickets:
   - **Already answered** by the spec, the conversation or the code: add
     the answer to the ticket.
   - **Minor:** a sensible builder could decide it without changing what
     gets built. Decide it, and mark it in the ticket as your call.
   - **The user's:** only they can answer, and the answer changes what
     gets built. Ask these in one message, most important first, saying
     which ticket each is for.

4. **Update the tickets** with the answers (`gh issue edit`). Remove the
   `ready-for-agent` label from any ticket still waiting on the user, and
   put it back once it's answered. List the calls you made so the user can
   check them, and stop.

---
Adapted from the builder check in `brainstorming`
([obra/superpowers](https://github.com/obra/superpowers), MIT).
