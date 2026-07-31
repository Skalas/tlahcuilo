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
    -h|--help) { [ -r "$SELF" ] && sed -n '2,18p' "$SELF"; } || echo "usage: install.sh [--link] [--update] [--user | --project [PATH]]"; exit 0 ;;
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

echo ""
echo "No project bootstrap needed — the skill creates .write/ and its profile on first run."
echo "Start a run with:  /tlahcuilo   (or ask for the writing panel by name)"
