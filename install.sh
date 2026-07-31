#!/usr/bin/env bash
# Installer for the `tlahcuilo` writing-panel skill.
#
#   ./install.sh --user              install at user level (~/.claude/skills)
#   ./install.sh --project [PATH]    install into a project's skill root
#                                    (.claude/skills)
#   ./install.sh --link [--user|--project [PATH]]
#                                    symlink the checkout instead of copying —
#                                    for the machine you AUTHOR the skill on, so
#                                    edits land in git instead of drifting
#   ./install.sh --update [...]      refresh an installed copy to this version
#
# Run from a local checkout, or straight from GitHub:
#   curl -fsSL https://raw.githubusercontent.com/Skalas/tlahcuilo/main/install.sh | bash -s -- --user
#
# Default scope is --user.
set -euo pipefail

REPO_URL="${TLAHCUILO_REPO:-https://github.com/Skalas/tlahcuilo.git}"
REPO_REF="${TLAHCUILO_REF:-main}"
SCOPE="user"
PROJECT="$PWD"
UPDATE=0
LINK=0

# Where do the skills come from? A real local checkout if this script is a regular file
# sitting next to skills/; otherwise clone from GitHub (so `curl … | bash` works).
# Piped execution (curl | bash): BASH_SOURCE[0] is bash/-/dev/fd/* — dirname resolves
# to cwd, which would false-positive as a checkout if the user happens to be in one.
SELF="${BASH_SOURCE[0]:-$0}"
SELF_DIR="$(cd "$(dirname "$SELF")" 2>/dev/null && pwd || true)"
SRC=""
LOCAL_CHECKOUT=0
case "$SELF" in
  bash|dash|sh|-) ;;
  /dev/fd/*|/dev/stdin|/proc/self/fd/*) ;;
  *)
    if [ -f "$SELF" ] && [ -r "$SELF" ] && [ "$(basename "$SELF")" = "install.sh" ] \
        && [ -n "${SELF_DIR:-}" ] && [ -d "$SELF_DIR/skills" ]; then
      LOCAL_CHECKOUT=1
    fi
    ;;
esac
[ "$LOCAL_CHECKOUT" -eq 1 ] && SRC="$SELF_DIR/skills"

while [ $# -gt 0 ]; do
  case "$1" in
    --user)    SCOPE="user"; shift ;;
    --project) SCOPE="project"; shift; [ $# -gt 0 ] && [[ "$1" != --* ]] && { PROJECT="$1"; shift; } ;;
    --update)  UPDATE=1; shift ;;
    --link)    LINK=1; shift ;;
    # 2,16 is the header comment block — it ends at "Default scope", just before `set -euo`.
    -h|--help) { [ -r "$SELF" ] && sed -n '2,16p' "$SELF"; } || echo "usage: install.sh [--link] [--update] [--user | --project [PATH]]"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

# --- prerequisites: panelist CLIs -----------------------------------------
# Every tier needs `codex` — without it there is no valid panel (SKILL.md, Step 1b), so
# a missing codex is fatal. `cursor-agent` is optional: its absence only degrades
# panel/full → duet, which the skill handles at runtime.
if command -v codex >/dev/null 2>&1; then
  echo "▸ prerequisite ok: codex found — every tier can run"
else
  echo "✗ prerequisite missing: codex (required — every tier includes it as a panelist)" >&2
  echo "    install the Codex CLI, then re-run this installer" >&2
  exit 1
fi
if command -v cursor-agent >/dev/null 2>&1; then
  echo "▸ optional ok: cursor-agent found — panel/full tiers available"
else
  echo "▸ optional missing: cursor-agent — runs will degrade to the duet tier"
fi

# --- external dependency: the base voice fingerprint ----------------------
# The voice pass (Step 3) layers a doc-type register over an invariant base fingerprint that
# lives in the PERSONAL layer, not in this repo — deliberately: it is your writing, not skill
# code. Absent, the skill still runs; the voice pass just falls back to register-only.
FINGERPRINT="$HOME/.claude/skills/writing-voice/my-voice.md"
if [ -f "$FINGERPRINT" ]; then
  echo "▸ voice base ok: $FINGERPRINT"
else
  echo "▸ voice base absent: $FINGERPRINT"
  echo "    the voice pass will run register-only until the writing-voice fingerprint exists"
  echo "    build it first with the writing-voice skill (it reads 2-3 of your samples)"
fi

# No local skills/ → fetch them from GitHub into a temp checkout.
if [ -z "$SRC" ]; then
  [ "$LINK" -eq 1 ] && { echo "--link requires a local checkout (nothing to link to)" >&2; exit 1; }
  command -v git >/dev/null 2>&1 || { echo "git is required to install from GitHub" >&2; exit 1; }
  echo "▸ fetching tlahcuilo ($REPO_REF) from $REPO_URL"
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  git clone --depth 1 --branch "$REPO_REF" "$REPO_URL" "$TMP/tlahcuilo" >/dev/null 2>&1 \
    || { echo "clone failed: $REPO_URL ($REPO_REF)" >&2; exit 1; }
  SRC="$TMP/tlahcuilo/skills"
fi

install_skills() {  # $1 = destination skills root
  local root="$1"
  mkdir -p "$root"
  for dir in "$SRC"/*/; do
    local name; name="$(basename "$dir")"
    # Intentionally replaces any same-named skill in the destination. This repo ships
    # only `tlahcuilo`, so nothing else can be clobbered.
    rm -rf "${root:?}/$name"
    if [ "$LINK" -eq 1 ]; then
      ln -s "${dir%/}" "$root/$name"
      echo "  ✓ $name → $root/$name (symlink → checkout)"
    else
      cp -R "$dir" "$root/$name"
      echo "  ✓ $name → $root/$name"
    fi
  done
}

VERB="installing"; [ "$UPDATE" = 1 ] && VERB="updating"
[ "$LINK" = 1 ] && VERB="linking"

# Claude-only, unlike metate: SKILL.md declares `compatibility: claude-code` and the
# pipeline is written around a Claude session as orchestrator (it spawns codex/cursor as
# panelists). Installing into a Codex skill root would advertise a surface that cannot
# actually run the skill.
if [ "$SCOPE" = "user" ]; then
  echo "▸ $VERB tlahcuilo at USER level"
  install_skills "$HOME/.claude/skills"
else
  echo "▸ $VERB tlahcuilo into PROJECT: $PROJECT"
  install_skills "$PROJECT/.claude/skills"
fi

# --- voice registers: prepare the home, report the gaps -------------------
# What an installer can honestly do: create the directory, put the template where you'll
# author, and say which doc types have no register yet. What it CANNOT do is write one — a
# register is derived from your samples or a short interview, which is the skill's job
# (SKILL.md → Step 0b). So this scaffolds and reports; it never fabricates a voice.
# Keep this default in sync with voice.registersDir in profile.template.yml — the contract
# test fails if the two drift.
REGISTERS_DEFAULT="$HOME/.claude/skills/writing-voice/registers"
REGISTERS_DIR="${TLAHCUILO_REGISTERS_DIR:-$REGISTERS_DEFAULT}"
mkdir -p "$REGISTERS_DIR"
cp "$SRC/tlahcuilo/voices/_template.md" "$REGISTERS_DIR/_template.md"
echo "▸ registers dir ready: $REGISTERS_DIR"
echo "  ✓ _template.md (how to write a register) → $REGISTERS_DIR"

# Scaffolding a custom dir is only half the job: runs resolve registers from the PROFILE, not
# from this script. Left unsaid, the override silently produces a base-only voice pass — the
# installer prepared one directory and every run reads another.
if [ "$REGISTERS_DIR" != "$REGISTERS_DEFAULT" ]; then
  echo "  ! custom location — runs read voice.registersDir from .write/profile.yml, not this env var."
  echo "    Set it there too, or registers written here are never loaded:"
  echo "      registersDir: $REGISTERS_DIR"
fi

# -s not -f: an empty file is a register someone started and abandoned. Counting it as present
# hides the gap behind a green "5/5" while the voice pass has nothing to overlay.
missing=()
present=0
for r in "$SRC"/tlahcuilo/rubrics/*.md; do
  t="$(basename "$r" .md)"; [ "$t" = "_template" ] && continue
  if [ -s "$REGISTERS_DIR/$t.md" ]; then present=$((present + 1)); else missing+=("$t"); fi
done
total=$((present + ${#missing[@]}))
echo "  registers: $present/$total present"
if [ "${#missing[@]}" -gt 0 ]; then
  echo "  no register yet for: ${missing[*]}"
  echo "    those doc types run in your BASE voice — correct, but not tuned to the situation"
fi

echo ""
echo "No project bootstrap needed — the skill creates .write/ and its profile on first run."
if [ "${#missing[@]}" -gt 0 ]; then
  echo ""
  echo "Next: build the registers you actually need. In Claude Code, run"
  echo "    /tlahcuilo registers"
  echo "and it will, per doc type, either read 2-3 of your past pieces of that kind or ask you"
  echo "4-5 questions, then write the overlay to $REGISTERS_DIR."
  echo "Build them as you need them — one register for the kind of doc you write next is enough"
  echo "to start; there is no reason to author all $total up front."
else
  echo "Start a run with:  /tlahcuilo   (or ask for the writing panel by name)"
fi
