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
./install.sh --user          # copy into ~/.claude/skills and ~/.agents/skills
```

Or without a checkout:

```bash
curl -fsSL https://raw.githubusercontent.com/Skalas/tlahcuilo/main/install.sh | bash -s -- --user
```

On the machine where you **author** the skill, install with `--link` instead. That symlinks the
checkout into the skill roots, so every edit you make while using the skill is an edit to this
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

The voice pass reads two layers:

1. **Base fingerprint** — `~/.claude/skills/writing-voice/my-voice.md`, owned by the
   [`writing-voice`](https://github.com/Skalas/claude-kits) skill in the personal `~/.claude`
   layer. **Not vendored here, on purpose:** it is your writing, not skill code, and it should
   not travel with a repo you may publish.
2. **Register overlay** — `skills/tlahcuilo/voices/<register>.md`, versioned here. Each one is a
   short diff against the base ("same fingerprint EXCEPT …") covering person, formality,
   hedging, and structural density for one doc type.

If the fingerprint is missing, runs still work — the voice pass falls back to register-only and
says so.

## Layout

```
skills/tlahcuilo/
  SKILL.md              the pipeline: setup → frame → debate/joust → voice pass → deliver
  ADAPTERS.md           per-CLI start/resume/critique commands, verbatim relay, isolation
  profile.template.yml  copied to .write/profile.yml on first run in a project
  position.schema.json  the JSON contract every panelist returns
  rubrics/<type>.md     the shared scorecard the panel argues from, per doc type
  voices/<register>.md  register overlays, per doc type
```

Adding a doc type means adding a `rubrics/<type>.md` + `voices/<type>.md` pair and uncommenting
the matching `docTypes.<type>` block in the profile template. `make test` fails if a `docTypes`
entry points at a rubric or register file that does not exist, so the two never drift apart.

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
