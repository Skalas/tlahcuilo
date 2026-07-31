# Rubric — Technical / consulting report

For deliverables a client **pays for and acts on**: verification reports, technical audits,
assessment findings, consulting recommendations. The reader's test is not "was this thorough" but
"can I trust these findings and act on them without re-doing the work." Often a mixed audience —
technical implementers plus non-technical decision-makers (PMs, clinical leads, funders). Every
panelist scores against these criteria and argues from them; a position that doesn't map to a
criterion is out of scope.

## Criteria

1. **Accurate & evidenced** — Every finding is traceable to a concrete source (file:line, an
   issue, a measured number). No claim the underlying material can't support. Flag any assertion
   that reads as opinion dressed as fact, or a number with no provenance.
2. **Clear to a mixed audience** — A clinical lead or a funder can follow the significance without
   reading code; an engineer can act on the detail. Jargon is either explained or justified. Flag
   passages only the author's team could parse.
3. **Severity & prioritization sound** — Findings are ranked by real clinical/operational risk,
   and the ranking is justified (why is this P0 and that P2?). Flag a flat list that makes the
   reader do the triage, or a severity that doesn't match the described impact.
4. **Actionable** — Each finding pairs with a concrete next step (fix, owner, or decision needed).
   The reader finishes knowing what to *do*, not just what's wrong. Flag findings that dead-end.
5. **Structured & navigable** — Sections are ordered by what the reader needs, the executive
   summary stands on its own, and a specific finding is findable. Flag burying the lede or a
   summary that just lists section titles.
6. **Scope-disciplined** — Stays inside the engagement, states what is out of scope and why, and
   doesn't overreach into claims the work didn't cover. Flag scope creep and silent gaps alike.
7. **Balanced & credible** — Acknowledges what works, not only defects; measured, not alarmist or
   promotional. Confidence is calibrated — certain where the evidence is, explicit where it isn't.
   Flag both over-claiming and false modesty.

## Scoring (joust mode)

Score each criterion 1–5:
- **5** exemplary · **4** solid, minor gaps · **3** usable, real gaps · **2** would mislead the
  client · **1** absent/broken.

## What debate should surface here

- A finding stated more strongly than its evidence supports.
- Severity/priority that doesn't track the actual described impact.
- A recommendation with no owner, no next step, or no feasibility check.
- Technical detail a non-technical decision-maker can't act on — or oversimplification that
  misleads an implementer.
- Scope creep, or a gap the report walks past without naming.
- Alarmist or promotional tone where measured would be more credible.

## Voice note

Consulting-report voice: measured, evidence-first, `we`/impersonal — not blog musing, not
corporate slop. See `<registersDir>/report.md` for the register overlay applied in Step 3.
