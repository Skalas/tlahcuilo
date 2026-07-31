#!/usr/bin/env bash
# Contract checks for the tlahcuilo skill. Structural only — no model calls, no network.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL="$ROOT/skills/tlahcuilo"
PROFILE="$SKILL/profile.template.yml"
fail=0
note() { echo "  $1"; }
bad()  { note "✗ $1"; fail=1; }

# --- 1. every doc type resolves to a real rubric + register ----------------
# Commented-out docTypes blocks are inert by design, so matching only uncommented
# `rubric:`/`register:` lines is the whole point: an ENABLED type must resolve.
while read -r rel; do
  [ -f "$SKILL/$rel" ] || bad "profile references missing rubric: $rel"
done < <(grep -E '^[[:space:]]+rubric:' "$PROFILE" | awk '{print $2}')

registers_dir="$(grep -E '^[[:space:]]+registersDir:' "$PROFILE" | awk '{print $2}')"
[ -n "$registers_dir" ] || bad "profile has no voice.registersDir"
while read -r reg; do
  [ -f "$SKILL/$registers_dir/$reg.md" ] \
    || bad "profile references missing register: $registers_dir/$reg.md"
done < <(grep -E '^[[:space:]]+register:' "$PROFILE" | awk '{print $2}')
[ "$fail" -eq 0 ] && note "✓ every enabled docType resolves to a rubric + register"

# --- 2. rubric/register pairs are symmetric --------------------------------
# A rubric without its register means the voice pass silently degrades to base-only
# for that doc type — a quiet quality loss, so treat the gap as a failure.
for r in "$SKILL"/rubrics/*.md; do
  n="$(basename "$r" .md)"; [ "$n" = "_template" ] && continue
  [ -f "$SKILL/$registers_dir/$n.md" ] || bad "rubric $n.md has no matching register"
done
for v in "$SKILL/$registers_dir"/*.md; do
  n="$(basename "$v" .md)"; [ "$n" = "_template" ] && continue
  [ -f "$SKILL/rubrics/$n.md" ] || bad "register $n.md has no matching rubric"
done

# --- 3. the panelist JSON contract is valid + covers every tier's seats ----
python3 -m json.tool "$SKILL/position.schema.json" >/dev/null \
  || bad "position.schema.json is not valid JSON"
# Tiers name their seats; the schema's panelist enum must admit each one, or a
# panelist's output fails validation the moment that tier is selected.
seats="$(sed -n '/^tiers:/,/^[a-z]/p' "$PROFILE" \
  | grep -E '^[[:space:]]+panelists:' \
  | sed 's/.*\[\(.*\)\].*/\1/' | tr ',' '\n' | tr -d ' ' | sort -u)"
for seat in $seats; do
  grep -q "\"$seat\"" "$SKILL/position.schema.json" \
    || bad "tier seat '$seat' is absent from position.schema.json"
done
[ -n "$seats" ] || bad "no tier panelists found in $PROFILE"

# --- 4. the skill's own frontmatter ---------------------------------------
for key in name description; do
  grep -q "^$key:" "$SKILL/SKILL.md" || bad "SKILL.md missing $key:"
done

# --- 5. the voice fingerprint is an EXTERNAL path, never vendored ---------
# Vendoring the base fingerprint would put the user's writing into a publishable repo.
[ -e "$SKILL/my-voice.md" ] && bad "my-voice.md is vendored into the skill — it belongs to ~/.claude"
grep -q 'fingerprint:.*writing-voice/my-voice.md' "$PROFILE" \
  || bad "profile's voice.fingerprint no longer points at the writing-voice base"

[ "$fail" -eq 0 ] && { note "✓ contracts ok"; exit 0; } || exit 1
