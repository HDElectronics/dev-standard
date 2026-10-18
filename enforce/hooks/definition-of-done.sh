#!/usr/bin/env bash
# AGT-003: the agent can't finish while the fast checks fail.
# Stop hook. Runs the command in .dev-standard.json "checks.fast" when the working tree
# has changes. Blocks up to 3 times per session, then lets the agent stop so it can
# report the failure honestly instead of looping.
source "$(dirname "$0")/lib.sh"
ds_need_jq
ds_read_input

check=$(ds_conf '.checks.fast' '')
[[ -n "$check" ]] || exit 0
[[ -n "$(git -C "$DS_ROOT" status --porcelain 2>/dev/null)" ]] || exit 0

session=$(ds_field '.session_id')
counter="${TMPDIR:-/tmp}/dev-standard-dod-${session:-unknown}"
max_blocks=3

if output=$(cd "$DS_ROOT" && timeout 540 bash -c "$check" 2>&1); then
  rm -f "$counter"
  exit 0
fi

count=$(( $(cat "$counter" 2>/dev/null || echo 0) + 1 ))
if (( count > max_blocks )); then
  rm -f "$counter"
  echo "AGT-003: '$check' still fails after $max_blocks attempts. Stopping is allowed; the agent must report the failure." >&2
  exit 1
fi
echo "$count" >"$counter"

ds_fail AGT \
  "AGT-003: '$check' failed (attempt $count of $max_blocks). Fix it before finishing, or explain to the user why it can't pass." \
  "Last lines of output:" \
  "$(tail -n 40 <<<"$output")"
