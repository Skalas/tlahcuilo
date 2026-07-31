#!/usr/bin/env bash
# Contract checks for the tlahcuilo skill. Structural only — no model calls, no network.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL="$ROOT/skills/tlahcuilo"
PROFILE="$SKILL/profile.template.yml"
fail=0
note() { echo "  $1"; }
bad()  { note "✗ $1"; fail=1; }

# --- 1. every enabled doc type resolves to a real rubric -------------------
# Commented-out docTypes blocks are inert by design, so matching only uncommented lines is the
# whole point: an ENABLED type must resolve. Registers can't be checked for existence — they live
# outside this repo by design — so the check on them is name-level: every `register:` must name a
# doc type that ships a rubric, which catches a typo'd or stale name.
rubrics=(); while read -r rel; do rubrics+=("$rel"); done \
  < <(grep -E '^[[:space:]]+rubric:' "$PROFILE" | awk '{print $2}')
# Without this guard the loop below is vacuous: a profile with every docType commented out would
# pass "every enabled docType resolves" while offering no selectable doc type at all.
[ "${#rubrics[@]}" -gt 0 ] || bad "profile enables no docType — nothing is selectable at runtime"
# ${arr[@]+…} guard: on bash 3.2 (macOS default) `"${arr[@]}"` on an EMPTY array trips `set -u`
# with "unbound variable". Reachable here — it is exactly the no-enabled-docType case above.
for rel in ${rubrics[@]+"${rubrics[@]}"}; do
  [ -f "$SKILL/$rel" ] || bad "profile references missing rubric: $rel"
done

regs=(); while read -r reg; do regs+=("$reg"); done \
  < <(grep -E '^[[:space:]]+register:' "$PROFILE" | awk '{print $2}')
[ "${#regs[@]}" -eq "${#rubrics[@]}" ] \
  || bad "profile has ${#rubrics[@]} enabled rubric(s) but ${#regs[@]} register(s) — every docType needs both"
for reg in ${regs[@]+"${regs[@]}"}; do
  [ -f "$SKILL/rubrics/$reg.md" ] \
    || bad "register name '$reg' matches no rubrics/$reg.md — typo, or a stale doc type"
done

registers_dir="$(grep -E '^[[:space:]]+registersDir:' "$PROFILE" | awk '{print $2}')"
[ -n "$registers_dir" ] || bad "profile has no voice.registersDir"
[ "$fail" -eq 0 ] && note "✓ all ${#rubrics[@]} enabled docTypes resolve to a rubric + a named register"

# --- 2. registers stay OUT of this repo -----------------------------------
# A filled-in register names real audiences and quotes real copy, so only the template
# ships. This is the check that keeps a published clone from carrying personal writing
# data — the failure it prevents is a privacy leak, not a broken run.
shipped=()
for v in "$SKILL/voices"/*.md; do
  n="$(basename "$v" .md)"; [ "$n" = "_template" ] && continue
  shipped+=("$n")
done
if [ "${#shipped[@]}" -eq 0 ]; then
  note "✓ voices/ ships the template only — registers live in voice.registersDir"
else
  bad "filled-in register(s) in voices/: ${shipped[*]} — move them to voice.registersDir"
fi
[ -f "$SKILL/voices/_template.md" ] || bad "voices/_template.md is missing"

# The default must point OUTSIDE the skill, or a filled-in register lands back in the repo
# (and, with a --link install, straight into git).
case "$registers_dir" in
  /*|~*) note "✓ registersDir default is external: $registers_dir" ;;
  *)     bad "registersDir default '$registers_dir' is inside the skill dir — registers would be committed" ;;
esac

# --- 3. the panelist JSON contract is valid + covers every tier's seats ----
if command -v python3 >/dev/null 2>&1; then
  python3 -m json.tool "$SKILL/position.schema.json" >/dev/null \
    || bad "position.schema.json is not valid JSON"
else
  note "– python3 absent, JSON validity not checked"   # exit 127 would read as invalid JSON
fi
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

# --- 3b. installer and profile agree on where registers live --------------
# The default path is declared twice (install.sh scaffolds it, the profile resolves it). If they
# drift, the installer prepares one directory and every run reads another — and the symptom is a
# silent base-only voice pass, not an error.
# Read the DEFAULT, not REGISTERS_DIR — the latter is the env-override expression.
inst_dir="$(grep -E '^REGISTERS_DEFAULT=' "$ROOT/install.sh" \
  | sed 's|^[^=]*=||; s|"||g; s|[$]HOME|~|')"
prof_dir="$registers_dir"
if [ "$inst_dir" = "$prof_dir" ]; then
  note "✓ install.sh and profile agree on registersDir ($prof_dir)"
else
  bad "registersDir drift — install.sh: '$inst_dir' vs profile: '$prof_dir'"
fi

# The installer seeds the template into that dir, so the template must exist to copy.
grep -q 'voices/_template.md' "$ROOT/install.sh" \
  || bad "install.sh no longer seeds voices/_template.md into the registers dir"

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
