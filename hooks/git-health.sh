#!/usr/bin/env bash
# Detects (and optionally repairs) a corrupted .git/HEAD.
set -euo pipefail
MODE="${1:-repair}"
GIT_DIR="$(git rev-parse --git-dir 2>/dev/null || echo .git)"
HEAD_FILE="$GIT_DIR/HEAD"

if [ -f "$GIT_DIR/index.lock" ]; then
  echo "git-health: stale $GIT_DIR/index.lock found. Is another process running git?"
fi

# Healthy means: one valid line and no NUL bytes anywhere in the file.
CLEAN="$(tr -d '\000\r' < "$HEAD_FILE" | head -1)"
NULS="$(tr -cd '\000' < "$HEAD_FILE" | wc -c)"
if [ "$NULS" -gt 0 ] || ! [[ "$CLEAN" =~ ^(ref:\ refs/heads/.+|[0-9a-f]{40})$ ]]; then
  if [ "$MODE" = "--check" ]; then
    echo "git-health: $HEAD_FILE is corrupted. Repair it with: scripts/git-health.sh"
    exit 1
  fi
  if ! [[ "$CLEAN" =~ ^(ref:\ refs/heads/.+|[0-9a-f]{40})$ ]]; then
    echo "git-health: no valid ref left in $HEAD_FILE. Fix it by hand, e.g.:"
    echo "  echo 'ref: refs/heads/main' > $HEAD_FILE"
    exit 1
  fi
  cp "$HEAD_FILE" "$HEAD_FILE.bak.$(date +%s)"
  printf '%s\n' "$CLEAN" > "$HEAD_FILE"
  echo "git-health: rewrote $HEAD_FILE (backup kept)."
else
  echo "git-health: HEAD OK ($CLEAN)"
fi
