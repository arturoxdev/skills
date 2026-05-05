---
name: grill-with-docs
description: Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise. Cross-checks the plan with Codex CLI as a second opinion at the start and end of the session. Use when user wants to stress-test a plan against their project's language and documented decisions.
---

<what-to-do>
Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before continuing.

If a question can be answered by exploring the codebase, explore the codebase instead.

This skill uses **Codex CLI** as a second opinion at two key moments:
1. **At the start** — before asking the first question, to surface concerns Claude might miss.
2. **At the end** — after all answers are in, to validate the consolidated plan and detect gaps.

If Codex's final review reveals gaps that Claude considers relevant, open a second round of questions. Loop until Claude has no more meaningful questions to ask.
</what-to-do>

<supporting-info>

## Domain awareness

During codebase exploration, also look for existing documentation:

### File structure

Most repos have a single context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `CONTEXT-MAP.md` exists at the root, the repo has multiple contexts. The map points to where each one lives:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files lazily — only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

## Codex CLI integration

Codex CLI is invoked from the terminal via Bash. It runs the `gpt-5-codex` model and gives a second perspective on the plan.

### How to invoke Codex

Always use the **non-interactive `exec` mode** with these flags:

```bash
codex exec \
  --model gpt-5-codex \
  --sandbox read-only \
  --cd "$(pwd)" \
  "<prompt here>"
```

Notes:
- `--sandbox read-only` lets Codex read files (including `CONTEXT.md`, `CONTEXT-MAP.md`, `docs/adr/`, and source) but never write.
- `--cd` anchors Codex to the project root so its file paths resolve correctly.
- `exec` is non-interactive: Codex returns a single response and exits. Do not try to chat with it turn-by-turn.
- Pass the entire prompt as a single quoted argument. For long prompts, write them to a temp file first and use `"$(cat /tmp/codex-prompt.md)"`.

### Step 1 — Initial Codex review (before the first question)

Right after exploring the codebase but **before asking the first question**, send Codex the user's plan and ask it to flag concerns. Tell Codex where to find context — let it read `CONTEXT.md` and `docs/adr/` on its own.

Use a prompt like:

```
You are giving a second opinion on a software plan.

The user's plan:
<<<
{paste user's plan verbatim}
>>>

Before responding:
1. Read CONTEXT.md (or CONTEXT-MAP.md if present) at the repo root.
2. Read all files under docs/adr/ — these are architecture decisions that constrain the plan.
3. If multiple contexts exist, read the relevant context's CONTEXT.md and docs/adr/.

Then return:
- Top 3-5 risks or unclear points in this plan.
- Any term in the plan that conflicts with CONTEXT.md's glossary.
- Any decision in the plan that contradicts an existing ADR.
- Questions that should be asked before this plan is finalised.

Be terse. Bullet points only. No preamble.
```

Capture Codex's output. **Do not show it to the user verbatim** — use it to inform which questions you ask. If Codex raised something Claude didn't think of, fold it into the question queue.

### Step 2 — Grilling loop

Run the interview as described in the rest of this skill (one question at a time, recommended answers, update `CONTEXT.md` inline, etc.). Codex's initial concerns become part of the question pool — Claude decides ordering and phrasing.

### Step 3 — Final Codex review (after all answers)

Once Claude has no more questions of its own, consolidate everything and send it to Codex:

```
You are reviewing a finalised plan against the user's answers.

Original request:
<<<
{user's original plan}
>>>

Q&A from the grilling session:
<<<
Q1: ...
A1: ...
Q2: ...
A2: ...
...
>>>

Decisions captured so far (from CONTEXT.md updates and proposed ADRs):
<<<
{summary}
>>>

Re-read CONTEXT.md and docs/adr/ to check for new contradictions introduced by the answers.

Return:
- Any answer that contradicts an existing ADR or glossary term.
- Any decision that is now ambiguous or under-specified.
- Concrete follow-up questions that should be asked before implementation starts.
- "NO_FURTHER_QUESTIONS" on its own line if the plan is coherent.

Be terse. Bullet points only.
```

### Step 4 — Filter and loop

Read Codex's response and **filter**:
- If Codex returns `NO_FURTHER_QUESTIONS` → end the session, summarise decisions, finalise pending `CONTEXT.md` / ADR writes.
- If Codex raised follow-ups → evaluate each one. Only ask the user the ones Claude considers genuinely relevant. Skip questions that:
  - Are already covered implicitly by an existing answer.
  - Are implementation details that don't change the design.
  - Restate something the user already settled.
- If at least one follow-up survives the filter → ask them (one at a time, same as before), then loop back to Step 3.

Stop the loop when either Codex returns `NO_FURTHER_QUESTIONS` or all of Codex's follow-ups get filtered out by Claude. State briefly to the user that a second-opinion review was run and the plan is coherent.

### Failure modes

- If `codex` is not installed or the command fails, tell the user once and continue the grilling without the second opinion. Do not block the session.
- If Codex takes too long or returns nonsense, ignore the output and proceed.
- Never let Codex's opinion override the user's stated intent — Codex is an advisor, not an authority.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up — capture them as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

Don't couple `CONTEXT.md` to implementation details. Only include terms that are meaningful to domain experts.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

</supporting-info>
