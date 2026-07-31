# Rubric — blog post

Personal technical blog. One author, one opinion, public internet. The reader arrived from a
search or a link, owes the post nothing, and leaves the moment it stops paying.

## Criteria

1. **hook** — Do the first three sentences give the reader a reason to continue that isn't
   curiosity about the author? Good: a concrete situation the reader recognizes, or the
   surprising claim stated flat. Bad: preamble, scene-setting, "in this post I will."
2. **one-idea** — Can you state the post's thesis in one sentence, and does every section serve
   it? A post that teaches three things well is three posts. Digressions that don't feed the
   thesis are cuts, however good they are.
3. **earns-its-length** — Does every paragraph carry weight the previous one didn't? Score down
   for restated points, throat-clearing transitions, and examples that prove something already
   proven. Length is not the problem; unearned length is.
4. **technical-honesty** — Are the claims true of the system that actually exists? Score down
   for a design described as more elegant than what was built, for advice the author has never
   run, and for numbers or benchmarks that can't be traced. A post that describes an idealized
   version of the code is a lie with good intentions.
5. **reproducible** — Could a competent reader build this from the post? Are the load-bearing
   details present (the gotcha, the constraint, the thing that breaks), or only the happy path?
   Code shown must be consistent with the prose describing it.
6. **voice** — Does it sound like a person with an opinion, or like documentation? First person
   where a choice was made. Failures named flatly. No hedging in front of strong claims.
7. **ending** — Does the last paragraph point somewhere — an action, a stake, a consequence —
   rather than summarizing what was just read?

## Scoring (joust mode)

Score each criterion 1–5: **5** exemplary · **4** solid, minor gaps · **3** usable, real gaps ·
**2** would mislead the reader · **1** absent/broken.

## What debate should surface here

- **The elegant lie** — a mechanism described the way the author wishes he'd built it. The most
  dangerous failure in a technical post, because it's invisible to anyone without the source.
- **The missing constraint** — the post works because of something unstated (a scale, a
  platform, a data shape). The reader builds it, hits the wall, blames themselves.
- **Tutorial drift** — a post with a thesis slowly turning into a README. Symptom: sections that
  would survive unchanged in the project's docs.
- **Unearned universality** — one person's setup stated as what everyone should do, without the
  conditions that make it true.
- **Prose/code disagreement** — the snippet does something other than what the sentence above it
  claims. Reviewers must actually read the code blocks.
- **The buried lede** — the most interesting claim sitting in paragraph nine.

## Voice note

Pairs with `voices/blog.md`. This is the register closest to the base fingerprint — the base was
extracted from two blog posts — so the overlay is thin: keep first person, keep the dry asides,
keep the flat admission of what broke.
