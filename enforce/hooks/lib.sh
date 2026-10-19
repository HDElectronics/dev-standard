#!/usr/bin/env bash
# Shared helpers for dev-standard agent hooks. Sourced by each hook, not run directly.
# Claude Code hook contract: JSON arrives on stdin; exit 2 blocks and shows stderr to the
# agent; other non-zero codes show stderr to the user without blocking. PreToolUse and
# PostToolUse hooks can also print hookSpecificOutput.additionalContext on exit 0, which
# reaches the agent without blocking; warn mode uses that.
set -euo pipefail

DS_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
DS_MANIFEST="$DS_ROOT/.dev-standard.json"
DS_INPUT=""

ds_need_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "dev-standard: jq is not installed, so $(basename "$0") was skipped. Install jq to enable it." >&2
    exit 1
  fi
}

# Read the hook payload once. Repos that haven't adopted the standard (no .dev-standard.json)
# are left alone, so the hooks are safe to load globally through the plugin.
ds_read_input() {
  DS_INPUT=$(cat)
  [[ -f "$DS_MANIFEST" ]] || exit 0
}

# ds_field <jq-filter>: a field of the hook payload, empty when missing.
ds_field() { jq -r "$1 // empty" <<<"$DS_INPUT"; }

# ds_git_dir: the directory a shell command's git commit or push runs in. Agents often work
# in a git worktree outside the project folder (the folder may serve a live app and stay on
# main), reached with `cd <dir> && git commit` or `git -C <dir> commit`. Reading the branch
# of the project folder there blocks every commit on the worktree's branch. So: start from
# the payload's cwd (else the project root) and follow each `cd` or `-C` directory before the
# first git commit/push, in order, the way the shell would. A directory that doesn't resolve
# (a shell variable, a typo) is skipped, so an unreadable command stays where it started and
# the check still applies there.
ds_git_dir() {
  local cmd dir head candidate next
  cmd=$(ds_field '.tool_input.command')
  dir=$(ds_field '.cwd')
  [[ -n "$dir" && -d "$dir" ]] || dir="$DS_ROOT"
  head=$(awk 'match($0, /git[ \t]+(commit|push)/) { print substr($0, 1, RSTART - 1); exit } { print }' <<<"$cmd")
  while IFS= read -r candidate; do
    candidate=$(sed -E "s/^.*(cd|-C)[[:space:]]+//; s/^[\"']//; s/[\"']\$//" <<<"$candidate")
    if next=$(cd "$dir" 2>/dev/null && cd "$candidate" 2>/dev/null && pwd); then
      dir="$next"
    fi
  done < <(grep -oE "(^|[[:space:];&|(])(cd|-C)[[:space:]]+(\"[^\"]*\"|'[^']*'|[^[:space:];&|)]+)" <<<"$head" || true)
  printf '%s' "$dir"
}

# ds_rel_path: the tool's target file, relative to the project root.
ds_rel_path() {
  local file
  file=$(ds_field '.tool_input.file_path')
  printf '%s' "${file#"$DS_ROOT"/}"
}

# ds_new_text: all text the Edit, Write or MultiEdit call would write.
ds_new_text() {
  jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits[]?.new_string)]
         | map(select(. != null)) | join("\n")' <<<"$DS_INPUT"
}

# ds_conf <jq-filter> <default>: a value from .dev-standard.json.
ds_conf() {
  local value=""
  if [[ -f "$DS_MANIFEST" ]]; then
    value=$(jq -r "$1 // empty" "$DS_MANIFEST" 2>/dev/null || true)
  fi
  printf '%s' "${value:-$2}"
}

# ds_level <PREFIX>: block | warn | off for a rule group.
ds_level() {
  ds_conf ".enforcement.groups.\"$1\"" "$(ds_conf '.enforcement.default' 'block')"
}

# ds_waived <RULE-ID> <relative-path>: succeeds when an unexpired waiver covers the path.
ds_waived() {
  [[ -f "$DS_MANIFEST" ]] || return 1
  jq -e --arg rule "$1" --arg path "$2" --arg today "$(date +%F)" '
    any(.waivers[]?; . as $w
      | $w.rule == $rule
      and (($w.expires // "9999-12-31") >= $today)
      and ($path | startswith($w.scope // "")))' "$DS_MANIFEST" >/dev/null 2>&1
}

# ds_fail <PREFIX> <line>...: block, warn or ignore, per the group's enforcement level.
ds_fail() {
  local prefix=$1; shift
  case "$(ds_level "$prefix")" in
    off) exit 0 ;;
    warn) ds_warn "$@" "(warning only: $prefix is set to warn in .dev-standard.json)" ;;
    *) printf '%s\n' "$@" >&2; exit 2 ;;
  esac
}

# ds_warn <line>...: tell the agent without blocking. Tool hooks use additionalContext;
# other events fall back to a non-blocking stderr notice for the user.
ds_warn() {
  local event message
  event=$(ds_field '.hook_event_name')
  message=$(printf '%s\n' "$@")
  if [[ "$event" == "PreToolUse" || "$event" == "PostToolUse" ]]; then
    jq -n --arg e "$event" --arg m "$message" '{hookSpecificOutput: {hookEventName: $e, additionalContext: $m}}'
    exit 0
  fi
  printf '%s\n' "$message" >&2
  exit 1
}

# ds_ask <reason>: hand the decision to the user through Claude Code's permission prompt.
ds_ask() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "ask", permissionDecisionReason: $r}}'
  exit 0
}
