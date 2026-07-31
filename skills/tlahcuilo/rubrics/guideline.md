# Rubric — Guidelines / standards

For documents others must **follow**: engineering standards, team playbooks, operating
guidelines, policy. The reader's test is not "was this nice to read" but "can I apply this
without asking a follow-up question." Every panelist scores the draft against these criteria and
argues from them — a position that doesn't map to a criterion is out of scope.

## Criteria

1. **Unambiguous & testable** — Every rule has one reading. A reader can tell whether they are
   in compliance without interpreting intent. Flag hedge words ("generally", "when appropriate",
   "as needed") that hide a decision the doc should make.
2. **Rationale present** — Each non-obvious rule says *why*. A rule without a reason gets
   cargo-culted or ignored the first time it's inconvenient. The why is what lets a reader apply
   judgment at the edges.
3. **Edge cases & exceptions** — The doc says what to do when the rule doesn't cleanly apply, and
   who decides. Silence on edge cases is where standards rot.
4. **Enforceable, not aspirational** — Rules map to something checkable (a review step, a tool, a
   gate) — not vibes. "Write clean code" is aspirational; "functions under ~20 lines, one level of
   abstraction" is enforceable.
5. **Internally consistent** — No rule contradicts another. Terminology is stable (same concept →
   same word). Examples match the rules they illustrate.
6. **Complete for its scope** — The doc covers the decisions a reader in this area will actually
   hit. Flag obvious gaps; flag scope creep into things this doc shouldn't own.
7. **Findable & scannable** — Structure lets a reader jump to the rule they need. Ordered by how
   often it's consulted, not by how it was written. Headings say what, not "Overview".

## Scoring (joust mode)

Score each criterion 1–5:
- **5** exemplary · **4** solid, minor gaps · **3** usable, real gaps · **2** would mislead a
  reader · **1** absent/broken.

## What debate should surface here

- Rules stated as preferences, or preferences dressed as rules.
- Missing rationale on the rules most likely to be resisted.
- Edge cases the author waved past ("we'll figure it out case by case").
- Two rules that quietly conflict.
- Aspiration masquerading as standard (nothing checkable behind it).

## Voice note

Guidelines are **not** blog voice. Imperative, direct, we/you, no discursive asides, no
first-person musing. See `<registersDir>/guideline.md` for the register overlay applied in Step 3.
