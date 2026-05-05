---
name: ask-altman
description: Consult Codex CLI (gpt-5.5) for a second opinion on the current session — typically after planning, design discussion, or a grilling like grill-with-docs. Gathers the relevant context from the conversation (plan, Q&A, decisions, doc updates), sends it to Codex with read-only access to the project, then presents Codex's findings concisely with light filtering. Use when the user invokes /ask-altman, or says "segunda opinión", "second opinion", "pregúntale a altman", "consulta a altman", "valida con codex".
---

<what-to-do>
Get a second opinion from Codex on whatever the user has been working on in this session. Gather the relevant context yourself from the conversation, send it to Codex, then present Codex's findings concisely with light filtering. Walk the user through the surviving follow-ups one at a time.

This skill never runs automatically. Only on explicit user request.
</what-to-do>

<supporting-info>

## Step 1 — Gather session context

Look at the conversation in your context. Extract the artefact under review. Typical pieces:

- The original plan, proposal, or topic the user brought.
- Any Q&A that happened (e.g., from a `grill-with-docs` session): pair as `Q1/A1`, `Q2/A2`, …
- Decisions captured (CONTEXT.md updates, proposed ADRs, choices the user committed to).
- Any other artefact directly relevant (open questions, rejected alternatives).

If the session was a free-form chat without structured grilling, just extract the equivalent: what's the proposal, what got discussed, what got decided. The skill works regardless of how the conversation was structured.

If there's nothing concrete to review yet, tell the user there's nothing for Codex to look at and stop.

## Step 2 — Build the Codex prompt

Construct a single prompt with this structure:

```
You are giving a second opinion on the user's session with Claude.

Artefact under review:
<<<
{the gathered context: proposal + Q&A + decisions, formatted clearly}
>>>

Return:
- Any decision that is ambiguous or under-specified.
- Any contradiction or risk you spot.
- Concrete follow-up questions before implementation starts.
- "NO_FURTHER_QUESTIONS" on its own line if the plan is coherent.

Be terse. Bullet points only. No preamble.
```

Do not tell Codex which files to read. Codex has read-only access to the project via its sandbox and will explore on its own.

## Step 3 — Run Codex (in an isolated subagent)

To keep the bash invocation and Codex's raw stdout out of the orchestrator's context, do not run `codex exec` directly. Launch a general-purpose subagent via the Agent tool (no `subagent_type` needed) and pass it this prompt:

> Execute the following bash command and return its stdout exactly as received. Do not add commentary, summaries, or framing.
>
> ```bash
> codex exec \
>     -m gpt-5.5 \
>     -c 'model_reasoning_effort="xhigh"' \
>     -s read-only \
>     -C "<cwd>" \
>     "<the Codex prompt built in Step 2>"
> ```
>
> For long prompts, write the prompt to `/tmp/ask-altman-prompt-<random>.md` first and invoke as `"$(cat /tmp/ask-altman-prompt-<random>.md)"`. Delete the temp file after.
>
> Sandbox is `read-only` by design — never change it.
>
> If codex is not installed or exits non-zero, return one line: `CODEX_UNAVAILABLE: <short reason>`. Do not retry more than once.
>
> Return Codex's stdout exactly. Nothing else.

Read what the subagent returns. If it's `CODEX_UNAVAILABLE: ...`, jump to "Failure handling". Otherwise proceed to Step 4 with the returned content.

## Step 4 — Present the response (concise)

Do not dump Codex's raw output. Synthesize. The user wants enough context to understand Codex's opinion in the fewest possible words — no preamble, no meta-narration.

**If Codex returned `NO_FURTHER_QUESTIONS`:** one line.

> Codex: plan coherente.

Stop.

**If Codex returned bullets:** filter aggressively. Skip:
- Items already answered implicitly by the session.
- Items that are purely implementation details (don't change the design).
- Restatements of points already settled.

Then present the survivors. Format:

> - **{título corto}** — {una frase con la sustancia: qué marcó Codex y por qué importa}
> - **{título corto}** — {una frase con la sustancia}
>
> ¿{pregunta concreta sobre el primero}?

Hard rules for the presentation:
- **One line per item, ≤ ~20 words.** Title + one sentence of substance. Cut anything else.
- **No "Codex revisó", "filtré N", "quedan M", "empecemos por".** The user infers structure from the list.
- **No numbered list, no bullets-of-bullets.** Flat dash list.
- **First question goes directly under the list.** No transition phrase.
- If you filtered something significant and the user should know, add **one short line at the end** ("descarté 2 puntos de implementación pura"). Optional — skip if obvious.

Walk through the survivors one at a time, waiting for the user's answer before moving to the next. If decisions land and the project has `CONTEXT.md` / `docs/adr/`, update them inline using the same conventions as `grill-with-docs`.

**No auto-loop.** When all filtered follow-ups are answered, stop. If the user wants another round, they invoke this skill again.

## Failure handling

If `codex` is not installed or the command fails (`command not found`, exit != 0, hangs):

> No pude correr Codex (razón breve). ¿Continuamos sin segunda opinión?

Tell the user once. Do not retry silently. Do not block the session.

</supporting-info>
