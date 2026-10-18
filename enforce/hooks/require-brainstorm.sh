#!/usr/bin/env bash
# BRN-001: a feature spec is written only after its brainstorm is decided.
# PreToolUse hook, matcher Edit|Write|MultiEdit. Fires on specs/NNN-slug/spec.md only.
source "$(dirname "$0")/lib.sh"
ds_need_jq
ds_read_input

rel=$(ds_rel_path)
[[ "$rel" =~ ^specs/[0-9]{3}-[^/]+/spec\.md$ ]] || exit 0
dir=$(dirname "$rel")
if ds_waived BRN-001 "$rel"; then exit 0; fi

record="$DS_ROOT/$dir/brainstorm.md"
if [[ -f "$record" ]] && grep -qiE '^status: *(decided|skipped)' "$record"; then exit 0; fi

hint="Run /brainstorm <slug> \"problem\" and let the user decide on the board."
waiting=$(compgen -G "$DS_ROOT/brainstorms/*/brainstorm.md" | sed "s#^$DS_ROOT/##" || true)
if [[ -n "$waiting" ]]; then
  hint="Brainstorms waiting to move: $(tr '\n' ' ' <<<"$waiting")- move the matching one with: git mv brainstorms/<slug>/brainstorm.* $dir/"
fi

ds_fail BRN \
  "BRN-001: $dir has no decided brainstorm.md, so the spec can't be written yet." \
  "$hint" \
  "Bug fixes and chores use fix/ or chore/ branches and need no brainstorm. Rule: .dev-standard/standards/brainstorm.md"
