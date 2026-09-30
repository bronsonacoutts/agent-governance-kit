#!/usr/bin/env bash
# Work-item reference guard: blocks a merge unless the branch name or PR title carries a real
# work-item key. The only opt-out is a visible label. Don't exempt branch-name patterns such as
# agent/* or ai/*: that's how agent pull requests slip past both this gate and the review gate.
#
# Env:
#   HEAD_REF          source branch (refs/heads/ prefix is stripped)
#   PR_TITLE          pull request title
#   LABELS            PR labels in any text form (JSON array, comma list, ...)
#   WORK_ITEM_PREFIX  key prefix, default PROJ  (keys look like PROJ-123)
#   OPT_OUT_LABEL     default "governance"  (internal tooling/docs work with no product ticket)
#   AUTOMATION_BRANCHES  ERE for dependency/release bots, default '^(dependabot|renovate)/|^release-please--'
set -euo pipefail

HEAD_REF="${HEAD_REF#refs/heads/}"
PREFIX="$(printf '%s' "${WORK_ITEM_PREFIX:-PROJ}" | tr -cd 'A-Za-z0-9')"
KEY="(^|[^A-Za-z0-9])${PREFIX}-[1-9][0-9]*([^0-9]|$)"
OPT_OUT="${OPT_OUT_LABEL:-governance}"
AUTOMATION="${AUTOMATION_BRANCHES:-^(dependabot|renovate)/|^release-please--}"

if printf '%s' "$HEAD_REF" | grep -qE "$AUTOMATION"; then
  echo "Automated dependency/release branch ($HEAD_REF): no work item required."; exit 0
fi
if printf '%s' "${LABELS:-}" | grep -qE "(^|[^A-Za-z0-9_-])${OPT_OUT}([^A-Za-z0-9_-]|$)"; then
  echo "Labelled '$OPT_OUT': no product work item required."; exit 0
fi
if printf '%s' "$HEAD_REF" | grep -qE "$KEY" || printf '%s' "${PR_TITLE:-}" | grep -qE "$KEY"; then
  echo "Work-item key found: OK"; exit 0
fi

echo "::error::No ${PREFIX}-<n> key in branch '$HEAD_REF' or the PR title."
echo "Rename the branch to <type>/${PREFIX}-<n>-<slug>, or add the '$OPT_OUT' label if this is"
echo "internal tooling or docs work with no product work item."
exit 1
