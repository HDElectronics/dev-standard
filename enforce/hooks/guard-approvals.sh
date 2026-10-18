#!/usr/bin/env bash
# BRN-004, SDD-001, ADR-005: only the user records a brainstorm decision, approves a spec
# or accepts an ADR.
# PreToolUse hook, matcher Edit|Write|MultiEdit.
source "$(dirname "$0")/lib.sh"
ds_need_jq
ds_read_input

rel=$(ds_rel_path)
text=$(ds_new_text)

case "$rel" in
  brainstorms/*/brainstorm.md | specs/*/brainstorm.md)
    if grep -qiE '^status: *(decided|skipped)' <<<"$text"; then
      ds_fail BRN \
        "BRN-004: the brainstorm decision is the user's to record." \
        "Ask the user to export brainstorm.md from the board and save it into $(dirname "$rel")/ themselves."
    fi
    ;;
  docs/adr/*.md)
    if grep -qiE '^status: *"?accepted' <<<"$text"; then
      ds_fail ADR \
        "ADR-005: only the decision-maker accepts an ADR. Keep 'status: proposed' and ask the user to accept it." \
        "To change an accepted decision, write a new ADR that supersedes it (ADR-004)."
    fi
    ;;
  specs/*/spec.md)
    if grep -qiE '^\*\*Status\*\*: *approved' <<<"$text"; then
      ds_fail SDD \
        "SDD-001: only the user approves a spec. Keep '**Status**: Draft' and ask the user to approve it." \
        "If you are changing an approved spec, set it back to Draft and run /speckit.clarify (SDD-006)."
    fi
    ;;
esac
exit 0
