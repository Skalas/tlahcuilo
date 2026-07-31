# Rubric — TEMPLATE

Copy to `rubrics/<doc-type>.md`, fill it, then uncomment the matching `docTypes.<type>` block in
`.write/profile.yml`. A rubric is the shared scorecard every panelist argues from — the debate has
no traction without it. Keep the criteria specific to THIS doc-type; don't reuse a generic list.

## Criteria

5–7 criteria, each a **testable question**, not a vibe. Give each a short kebab-case key (used as
`rubric_ref` in `position.schema.json`) and one line on what "compliant" means. Example shape:

1. **<key-one>** — <the question a reviewer can answer yes/no>. <what good looks like>.
2. **<key-two>** — …
3. …

Weight the criteria toward what actually makes THIS type succeed:
- proposal → clear ask, evidence, objection-handling, stakes, one-read decidability
- blog → hook, single idea, voice, earns its length, ending lands
- guideline → unambiguous/testable, rationale, edge-cases, enforceable, consistent
- general → purpose up front, structure serves reader, claims supported, nothing unearned

## Scoring (joust mode)

Score each criterion 1–5: **5** exemplary · **4** solid, minor gaps · **3** usable, real gaps ·
**2** would mislead the reader · **1** absent/broken.

## What debate should surface here

3–6 failure modes specific to this doc-type — the things a panelist should hunt for. (This is what
turns a generic critique into a useful one.)

## Voice note

Name the register (`voices/<register>.md`) that pairs with this doc-type and one line on how it
differs from the base fingerprint (person, formality, structure). The voice pass reads both.
