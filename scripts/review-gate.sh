#!/usr/bin/env bash
# Second-reader gate. Requires an approving review from someone other than the author when a change
# is agent-authored OR touches a high-risk path. It keys on what changed, not only on who pushed:
# agent sessions often push under an engineer's own identity, so an author-only gate never fires.
#
# Inputs (env):
#   AUTHOR_TYPE           User | Bot
#   HEAD_REF              source branch name
#   BODY                  pull request description
#   CHANGED_FILES         newline-separated changed paths
#   APPROVALS             approving reviews from people other than the author
#   HIGH_RISK_PATHS       optional ERE; tune it to your repo's security-relevant paths
#   AGENT_BRANCH_PATTERN  optional ERE for agent-created branches (default '^(agent|ai)/')
#   AGENT_FOOTER_PATTERN  optional ERE (case-insensitive) for the footer agent tools add to PR
#                         descriptions (default 'generated (with|by) '). Narrow it to your tools'
#                         exact footers if it catches too much; a false positive only asks for a review.
#
# Pair it with a CODEOWNERS file so the platform requests the right reviewer, e.g.:
#   /migrations/            @org/security-reviewers
#   /src/auth/              @org/security-reviewers
#   /src/billing/           @org/security-reviewers
#   /data/signed-records/   @org/domain-reviewers
set -euo pipefail

HIGH_RISK="${HIGH_RISK_PATHS:-^(migrations/|src/auth/|src/billing/|data/signed-records/|ci/workflows/|\.github/workflows/)}"
AGENT_BRANCH="${AGENT_BRANCH_PATTERN:-^(agent|ai)/}"
AGENT_FOOTER="${AGENT_FOOTER_PATTERN:-generated (with|by) }"

is_agent_authored() {
  [ "${AUTHOR_TYPE:-User}" = "Bot" ] && return 0
  echo "${HEAD_REF:-}" | grep -qE "$AGENT_BRANCH" && return 0
  # Agent sessions that push as a human usually still leave a generated-by footer.
  echo "${BODY:-}" | grep -qiE "$AGENT_FOOTER" && return 0
  return 1
}

risky_files="$(echo "${CHANGED_FILES:-}" | grep -E "$HIGH_RISK" || true)"
reasons=()
if is_agent_authored; then reasons+=("agent-authored"); fi
if [ -n "$risky_files" ]; then reasons+=("touches: $(echo "$risky_files" | head -3 | tr '\n' ' ')"); fi

if [ "${#reasons[@]}" -gt 0 ] && [ "${APPROVALS:-0}" -lt 1 ]; then
  echo "::error::This change needs an approving review from someone other than the author."
  echo "Reason: ${reasons[*]}"
  exit 1
fi
echo "Review gate OK."
