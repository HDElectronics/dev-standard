#!/usr/bin/env bash
# AGT-002, GIT-005, SEC-005, BRN-004, ADR-005, BRA-011: stop shell commands that skip checks,
# rewrite main, fake approvals, bypass branch protection, or destroy data without the user's say-so.
# PreToolUse hook, matcher Bash.
source "$(dirname "$0")/lib.sh"
ds_need_jq
ds_read_input

cmd=$(ds_field '.tool_input.command')
[[ -n "$cmd" ]] || exit 0
branch=$(git -C "$DS_ROOT" branch --show-current 2>/dev/null || true)

if grep -qE -- '--no-verify|(^|[[:space:]])(HUSKY|LEFTHOOK)=0' <<<"$cmd" \
   || grep -qE 'git[[:space:]]+commit([[:space:]]+[^|;&]*)?[[:space:]]-[a-zA-Z]*n' <<<"$cmd"; then
  ds_fail AGT "AGT-002: don't skip git hooks. Fix what the hook reports, or tell the user why it fails."
fi

if grep -qE 'git[[:space:]]+push' <<<"$cmd" && grep -qE -- '--force|[[:space:]]-f([[:space:]]|$)|[[:space:]]\+[^[:space:]]' <<<"$cmd"; then
  if grep -qE '(^|[[:space:]:/])(main|master)([[:space:]]|$)' <<<"$cmd" || [[ "$branch" == "main" || "$branch" == "master" ]]; then
    ds_fail GIT "GIT-005: never force-push main. Open a PR instead."
  fi
fi

if [[ "$branch" == "main" || "$branch" == "master" ]] && grep -qE 'git[[:space:]]+commit' <<<"$cmd"; then
  ds_fail GIT "GIT-005: don't commit on $branch. Create a branch first (BRA-003): NNN-slug for spec docs, NNN-tTTT-slug for a task, fix/slug or chore/slug otherwise."
fi

writes_files='sed[[:space:]]+(-[a-zA-Z]*[[:space:]]+)*-[a-zA-Z]*i|perl[[:space:]]+-[a-zA-Z]*i|tee[[:space:]]|>[[:space:]]*[^&[:space:]]|python[0-9.]*[[:space:]]+-c'
if grep -qiE '\*\*Status\*\*: *approved|status: *"?(decided|skipped|accepted)' <<<"$cmd" && grep -qE "$writes_files" <<<"$cmd"; then
  ds_fail SDD "SDD-001 / BRN-004 / ADR-005: approvals and decisions are recorded by the user, not by a shell command."
fi

if grep -qE 'gh[[:space:]]+pr[[:space:]]+merge([[:space:]].*)?--admin' <<<"$cmd"; then
  ds_fail BRA "BRA-011: don't merge past branch protection. Get the required reviews and checks instead."
fi

if grep -qE 'gh[[:space:]]+(api|ruleset)' <<<"$cmd" && grep -qE 'rulesets|/protection' <<<"$cmd" \
   && grep -qiE -- '(-X|--method)[[:space:]]*(POST|PUT|PATCH|DELETE)|--input|[[:space:]]-f[[:space:]]|[[:space:]]-F[[:space:]]' <<<"$cmd"; then
  ds_ask "BRA-011: this command changes branch protection or rulesets on the server. Confirm you want the agent to run it."
fi

if grep -qiE 'rm[[:space:]]+-[a-z]*r[a-z]*f|rm[[:space:]]+-[a-z]*f[a-z]*r|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+clean[[:space:]]+-[a-z]*f|drop[[:space:]]+(table|database|schema)|truncate[[:space:]]+table|docker[[:space:]]+(system|volume)[[:space:]]+prune' <<<"$cmd"; then
  ds_ask "SEC-005: this command deletes data or history. Confirm you want the agent to run it."
fi
exit 0
