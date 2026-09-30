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

# Git passes the refs being pushed on stdin: "<local ref> <local sha> <remote ref> <remote sha>".
# Checks read files from the working tree, so they can only vouch for HEAD. If a push includes a
# commit other than HEAD (e.g. `git push origin other-branch`), stop rather than approve commits
# nobody checked. Deletions (all-zero local sha) are skipped. Run by hand, with no stdin, the
# runner checks HEAD.
HEAD_SHA="$(git rev-parse HEAD)"
if [ ! -t 0 ]; then
  while read -r local_ref local_sha _remote_ref _remote_sha; do
    [ -z "${local_sha:-}" ] && continue
    case "$local_sha" in *[!0]*) ;; *) continue ;; esac
    commit="$(git rev-parse --verify --quiet "$local_sha^{commit}" || true)"
    if [ -n "$commit" ] && [ "$commit" != "$HEAD_SHA" ]; then
      echo "pre-push: this push includes $local_ref ($commit), which isn't the checked-out HEAD."
      echo "The checks read the working tree, so they can't vouch for it. Check that branch out and push"
      echo "it from there."
      exit 1
    fi
  done
fi

# Fail closed: without the base we can't see every commit on the branch, and checking only the
# last commit would silently miss violations in earlier ones.
if ! BASE="$(git merge-base HEAD "$BASE_REF" 2>/dev/null)"; then
  echo "pre-push: can't find the base ref $BASE_REF, so the branch's full diff can't be checked."
  echo "Run 'git fetch origin', or set BASE_REF to the branch this one targets."
  exit 1
fi
CHANGED_FILES="$(git diff --name-only "$BASE"...HEAD)"
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
