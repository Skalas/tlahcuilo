# tlahcuilo

A multi-model writing panel, packaged as a Claude Code skill.

[`metate`](https://github.com/Skalas/metate) hardens *code* by running review lenses over it.
`tlahcuilo` hardens *prose* by making different models **argue about it**. Claude, Codex, and
Cursor each hold a position across rounds — the orchestrating session relays their output
verbatim, applies a convergence rule, and finishes with a register-aware voice pass so the
merged result sounds like you rather than like a committee.

```
brief ─┐                                    ┌─ mode: debate → argue the draft
       ├─ draft (yours or Claude's) ────────┤
       │                                    └─ mode: joust  → models draft, then judge
       ▼
  DEBATE ROUNDS (Claude ⇄ Codex ⇄ Cursor, rebuttals)
       ▼
  SYNTHESIZE (apply consensus, record dissent)
       ▼
  VOICE PASS (base fingerprint + doc-type register)
       ▼
  final doc + debate transcript
```

## Install

```bash
git clone git@github.com:Skalas/tlahcuilo.git && cd tlahcuilo
./install.sh --user          # copy into ~/.claude/skills
```

Or without a checkout:

```bash
curl -fsSL https://raw.githubusercontent.com/Skalas/tlahcuilo/main/install.sh | bash -s -- --user
```

On the machine where you **author** the skill, install with `--link` instead. That symlinks the
checkout into the skill root, so every edit you make while using the skill is an edit to this
repo — no copy to drift, no re-install step, and `git diff` shows what a session changed.

```bash
./install.sh --link --user
```

### Prerequisites

| | required | why |
|---|---|---|
| `codex` | **yes** | every tier seats it as a panelist; without it there is no valid panel |
| `cursor-agent` | no | its absence degrades `panel`/`full` runs to the `duet` tier |
| `claude` | implicit | the orchestrator; also spawned as a separate voice in the `full` tier |

## Voice data lives outside this repo

This repo is the **engine**. Both layers of voice data it consumes are yours and stay in your own
layer:

1. **Base fingerprint** — `~/.claude/skills/writing-voice/my-voice.md`, produced by the
   `writing-voice` skill. The invariant you: word choice, tics, punctuation, rhythm.
2. **Register overlays** — `<voice.registersDir>/<register>.md`, one per doc type. A short diff
   against the base ("same fingerprint EXCEPT …") setting person, formality, hedging, and
   structural density. Default location is `~/.claude/skills/writing-voice/registers/`, beside
   the fingerprint.

Only `voices/_template.md` ships here. That is a deliberate boundary, not an oversight: a
filled-in register names its real audience and usually quotes real copy — a client's proposal
language, a named product, an actual speech — so it is personal data with the same handling
requirements as the fingerprint. `make test` fails if a filled-in register appears in `voices/`,
or if the profile's `registersDir` default points back inside the skill dir. With a `--link`
install the skill dir *is* the repo, so that second check is what stops a register you write
mid-run from landing in a public commit.

Missing either layer degrades rather than breaks: no fingerprint → register-only; no register for
the doc type → base-only, and the run tells you the piece is in your default voice rather than one
tuned to the situation.

### Building your registers

A fresh install ships zero registers, by definition — yours don't exist yet. The installer creates
the directory, drops the authoring template in it, and reports coverage against the shipped
rubrics:

```
▸ registers dir ready: ~/.claude/skills/writing-voice/registers
  registers: 0/5 present
  no register yet for: blog guideline proposal report speech
```

Then it hands off, because the rest isn't a shell job: a register is derived from *your* writing.
Run `/tlahcuilo registers` and the skill will, per doc type, either read 2–3 of your past pieces of
that kind or ask you 4–5 questions, then write the overlay to your `registersDir`. It writes only
the doc types you ask for — an unused register is a guess about writing you haven't shown it, and a
wrong register pulls the voice pass away from you rather than toward you. Build the one you need
next; add others when you need them.

Re-running the installer never touches a register you've written — it only refreshes the template
and re-reports coverage. `--update` is an alias for a plain re-install; it changes the wording, not
the behavior.

To keep registers somewhere else, set **both** halves: `TLAHCUILO_REGISTERS_DIR=...` tells the
installer where to scaffold, and `voice.registersDir` in `.write/profile.yml` is what every run
actually reads. Setting only the env var scaffolds a directory nothing loads from — the installer
warns and prints the profile line when it sees that.

## Layout

```
skills/tlahcuilo/
  SKILL.md              the pipeline: setup → frame → debate/joust → voice pass → deliver
  ADAPTERS.md           per-CLI start/resume/critique commands, verbatim relay, isolation
  profile.template.yml  copied to .write/profile.yml on first run in a project
  position.schema.json  the JSON contract every panelist returns
  rubrics/<type>.md     the shared scorecard the panel argues from, per doc type
  voices/_template.md   how to write a register (the registers themselves live in your layer)
```

Ships with rubrics for `guideline`, `proposal`, `blog`, `report`, and `speech`. Adding a doc type
means writing `rubrics/<type>.md` from `rubrics/_template.md`, writing the matching register into
your `registersDir`, and uncommenting the `docTypes.<type>` block in the profile template. A rubric
is publishable — it is a scorecard of testable questions, with no client language in it.

Adding a panelist means adding its start/resume/critique commands to `ADAPTERS.md` and a `panel`
entry to the profile. Nothing else in the skill is model-specific.

## Development

```bash
make help     # list targets
make check    # fast loop: shell syntax + shellcheck
make verify   # full gate: check + metadata/contract tests
```

## Runtime artifacts

A run writes to `.write/` in the target project: the profile, per-round positions, competing
drafts, the dissent log, and transcripts. Positions and transcripts retain the **full document
and the verbatim model exchange**, so Step 0 writes `.write/.gitignore` to keep all of it out of
the target repo's history. Set `output.keepTranscripts: false` to discard them after each run.

Before the first external call the skill discloses plainly that the document and every model's
output go to the external panelists you selected (Codex → OpenAI, Cursor → its backend) in
addition to Claude. For a confidential draft, that is the moment to stop.

## License

MIT — see [LICENSE](LICENSE).
