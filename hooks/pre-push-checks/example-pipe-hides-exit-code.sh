#!/usr/bin/env bash
# Example pre-push check. Name real checks after the work item that prompted them,
# e.g. PROJ-377-pipe-hides-exit-code.sh, and link the matching lesson file.
#
# Flags "cmd | head" in CI definitions: with strict shell options the step can pass while the first
# command failed, so a broken check reports green.
hits="$(printf '%s\n' "${CHANGED_FILES:-}" \
  | grep -E '^(\.github/workflows|ci/workflows|pipelines)/.*\.ya?ml$' \
  | while read -r f; do [ -f "$f" ] && grep -nHE '\|\s*head\b' "$f"; done || true)"
if [ -n "$hits" ]; then
  echo "Piping into head hides the first command's exit code:"
  echo "$hits"
  echo "Capture the output first, then take the first line."
  exit 1
fi
