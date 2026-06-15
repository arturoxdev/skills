---
  name: review-prd
  description: Use when the user asks to evaluate, review, stress-test, critique, or find gaps in a
  PRD, product spec, technical spec, RFC, proposal, or linked spec document. The user may paste the
  PRD directly or provide a link/path. Focus on gaps, edge cases, contradictions, domain
  invariants, permissions, data model risks, scope cuts, and testability.
  ---

  # PRD / Spec Gap Review

  ## Goal

  Review a PRD or spec as a senior product + architecture reviewer.

  Find:
  - domain gaps
  - edge cases
  - contradictions
  - ambiguous terms
  - hidden implementation risks
  - missing permission/state/data rules
  - bad scope boundaries
  - weak testing coverage

  Do not rewrite the PRD unless the user explicitly asks.

  ## Inputs

  The user may provide:
  - pasted PRD/spec text
  - local file path
  - repo doc path
  - external link
  - Linear/Notion/GitHub/etc. link if available through tools

  If a link/path is provided, retrieve/read the source before reviewing. If inaccessible, ask for
  the content.

  ## Context Check

  Before reviewing, look for nearby project context when available:
  - `AGENTS.md`
  - `CONTEXT.md`
  - `CONTEXT-MAP.md`
  - `docs/domain.md`
  - `docs/adr/`
  - `docs/specs/`
  - relevant schema/routes/engine files if the spec mentions implementation details

  Use existing domain language. If the PRD conflicts with glossary or ADRs, call it out explicitly.

  ## Review Lens

  Stress-test these areas:

  1. **Domain invariants**
     - What must always be true?
     - Are entities, ownership, lifecycle, and scope clearly defined?
     - Are derived values vs stored values clear?

  2. **States and transitions**
     - What creates, updates, completes, cancels, archives, or freezes each entity?
     - Are terminal states and rollback paths clear?

  3. **Permissions and visibility**
     - Who can see, create, edit, act, approve, delete, or administer?
     - Are admin permissions separated from operational permissions?

  4. **Data model**
     - Are uniqueness constraints, FK boundaries, soft-delete behavior, and indexes implied?
     - Are there collisions with existing schema assumptions?

  5. **Edge cases**
     - Empty sets
     - duplicates
     - partial completion
     - stale drafts
     - deleted users/catalog items
     - unauthorized deep-links
     - concurrent actions
     - migration/backfill/destructive reset

  6. **UX and workflow**
     - Does the user land in the right context?
     - Are selectors, filters, summaries, and empty/error states defined?
     - Is the workflow usable for the actor doing the work?

  7. **Aggregation and reporting**
     - Are formulas explicit?
     - Are totals derived consistently?
     - Are financial/progress metrics unambiguous?

  8. **Testing**
     - Prefer behavior tests: input → DB/API output/domain invariant.
     - Avoid tests that only verify implementation details.

  ## Output Style

  Be concise, direct, and specific. Do not be verbose. Prioritize what could break.

  Use this structure:

  ## Veredicto
  Short assessment: ready, mostly ready, needs adjustment, or incomplete.

  ## Gaps Críticos
  Numbered list. For each:
  - what is missing or contradictory
  - why it matters
  - concrete recommendation

  ## Edge Cases
  Specific cases the PRD/spec should handle explicitly.

  ## Preguntas Que Deben Cerrarse
  Decision questions only. No generic questions.

  ## Cómo Lo Dividiría
  Say whether it should stay one spec or be split.
  If split, cut by domain invariants / vertical slices, not by backend vs frontend.

  ## Testing Recomendado
  Behavioral tests that validate the main invariants.

  ## Recomendación Final
  Clear next step: approve, adjust, write ADR, split specs, block on input, etc.

  ## Rules

  - Do not implement code.
  - Do not rewrite the PRD unless asked.
  - If the spec contradicts existing docs/code, say so.
  - If something is underspecified, propose the most conservative domain-safe rule.
  - If an ADR is warranted, say why briefly.
  - Keep the final review high-signal and compact.
