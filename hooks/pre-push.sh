#!/usr/bin/env bash
# Pre-push review runner. Runs every check file in the checks folder, in name order, and aborts the
# push on any failure. Keep this runner frozen: a new check is a new file (named for the work item
# that prompted it), so parallel pull requests that each add a check never conflict.
#
# Each check is a bash script that exits non-zero with a human-readable message on a finding. It
# receives CHANGED_FILES (newline-separated paths changed on this branch vs the base).
#
# Env: BASE_REF (default origin/main), PRE_PUSH_CHECKS_DIR (default pre-push-checks)
# Wire from .husky/pre-push (or any hook manager):  bash scripts/pre-push.sh
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

BASE_REF="${BASE_REF:-origin/main}"
CHECKS_DIR="${PRE_PUSH_CHECKS_DIR:-pre-push-checks}"

if BASE="$(git merge-base HEAD "$BASE_REF" 2>/dev/null)"; then
  CHANGED_FILES="$(git diff --name-only "$BASE"...HEAD)"
else
  echo "pre-push: can't find $BASE_REF; checking files changed in the last commit only."
  CHANGED_FILES="$(git diff --name-only HEAD~1 HEAD 2>/dev/null || true)"
fi
export CHANGED_FILES

shopt -s nullglob
checks=("$CHECKS_DIR"/*.sh)
if [ "${#checks[@]}" -eq 0 ]; then
  echo "pre-push: no checks in $CHECKS_DIR/. Nothing to run."
  exit 0
fi
mapfile -t checks < <(printf '%s\n' "${checks[@]}" | LC_ALL=C sort)

FAILED=0
echo "pre-push review"
for check in "${checks[@]}"; do
  name="$(basename "$check" .sh)"
  if output="$(bash "$check" 2>&1)"; then
    echo "  ok    $name"
  else
    echo "  FAIL  $name"
    printf '%s\n' "$output" | sed 's/^/        /'
    FAILED=1
  fi
done

if [ "$FAILED" -eq 0 ]; then echo "No issues found."; else echo "push aborted"; exit 1; fi
