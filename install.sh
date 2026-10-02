#!/usr/bin/env bash
# Installs the agent governance kit into an existing git repository.
#
# usage: bash install.sh <target-repo> [options]
#   --prefix KEY        work-item key prefix, e.g. ABC for ABC-123 (default PROJ)
#   --platform NAME     github | azure (default: detected from the repo, else github)
#   --hooks             also install the local pre-commit/pre-push hooks
#   --roles             also install the Merge Trains and Dispatch role playbooks
#   --force             overwrite files that already exist (default: skip them)
#
# It only adds files. It never commits, pushes or changes repo settings, and it skips any file that
# already exists unless --force is given, so it's safe to re-run.
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
TARGET="" PREFIX="PROJ" PLATFORM="" HOOKS=0 ROLES=0 FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) PREFIX="${2:-}"; shift 2 ;;
    --platform) PLATFORM="${2:-}"; shift 2 ;;
    --hooks) HOOKS=1; shift ;;
    --roles) ROLES=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

[ -n "$TARGET" ] || { echo "usage: bash install.sh <target-repo> [--prefix KEY] [--hooks] [--roles]" >&2; exit 2; }
git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repository: $TARGET" >&2; exit 1; }
TARGET="$(git -C "$TARGET" rev-parse --show-toplevel)"
[ "$TARGET" != "$KIT" ] || { echo "Target is the kit itself. Pass the repo you want to install into." >&2; exit 1; }
printf '%s' "$PREFIX" | grep -qE '^[A-Za-z][A-Za-z0-9]*$' || { echo "--prefix must be letters and digits, e.g. ABC" >&2; exit 2; }

if [ -z "$PLATFORM" ]; then
  REMOTE="$(git -C "$TARGET" remote get-url origin 2>/dev/null || true)"
  if printf '%s' "$REMOTE" | grep -qE 'dev\.azure\.com|visualstudio\.com' || [ -f "$TARGET/azure-pipelines.yml" ]; then
    PLATFORM=azure
  else
    PLATFORM=github
  fi
fi
case "$PLATFORM" in github|azure) ;; *) echo "--platform must be github or azure" >&2; exit 2 ;; esac

ADDED=() SKIPPED=()
put() { # put <kit-relative source> <target-relative destination>
  local src="$KIT/$1" dst="$TARGET/$2"
  if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then SKIPPED+=("$2"); return; fi
  mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; ADDED+=("$2")
}
set_prefix() { # set_prefix <target-relative file> <sed expression>
  [ "$PREFIX" = PROJ ] && return
  printf '%s\n' "${ADDED[@]}" | grep -qxF "$1" || return 0
  sed -i.bak "$2" "$TARGET/$1" && rm -f "$TARGET/$1.bak"
}

# Core: rules, edit guard, CI gates.
put templates/AGENTS.md AGENTS.md
put hooks/branch-guard.mjs scripts/branch-guard.mjs
for f in "$KIT"/scripts/*.sh "$KIT"/scripts/*.mjs; do put "scripts/$(basename "$f")" "scripts/agent-governance/$(basename "$f")"; done
if [ "$PLATFORM" = github ]; then
  put ci/github/agent-governance.yml .github/workflows/agent-governance.yml
  set_prefix .github/workflows/agent-governance.yml "s/|| 'PROJ'/|| '$PREFIX'/"
  put templates/PULL_REQUEST_TEMPLATE.md .github/PULL_REQUEST_TEMPLATE.md
else
  put ci/azure-pipelines/agent-governance.yml pipelines/agent-governance.yml
  set_prefix pipelines/agent-governance.yml "s/^\(    value: \)PROJ$/\1$PREFIX/"
fi

# Claude Code edit hook: create the settings file only if there isn't one.
CLAUDE_HOOK=created
if [ -e "$TARGET/.claude/settings.json" ] && [ "$FORCE" -eq 0 ]; then
  grep -q 'branch-guard.mjs' "$TARGET/.claude/settings.json" && CLAUDE_HOOK=present || CLAUDE_HOOK=manual
else
  mkdir -p "$TARGET/.claude"
  cat > "$TARGET/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write|MultiEdit",
        "hooks": [ { "type": "command", "command": "node scripts/branch-guard.mjs" } ] }
    ]
  }
}
JSON
  ADDED+=(.claude/settings.json)
fi

if [ "$HOOKS" -eq 1 ]; then
  put hooks/git-health.sh scripts/git-health.sh
  put hooks/pre-push.sh scripts/pre-push.sh
  for f in "$KIT"/hooks/pre-push-checks/*; do put "hooks/pre-push-checks/$(basename "$f")" "pre-push-checks/$(basename "$f")"; done
fi
if [ "$ROLES" -eq 1 ]; then
  for f in "$KIT"/templates/roles/*.md; do put "templates/roles/$(basename "$f")" ".agents/roles/$(basename "$f")"; done
fi

echo "Installed the agent governance kit into $TARGET ($PLATFORM, keys like $PREFIX-123)."
[ ${#ADDED[@]} -eq 0 ] || { echo; echo "Added:"; printf '  %s\n' "${ADDED[@]}"; }
[ ${#SKIPPED[@]} -eq 0 ] || { echo; echo "Skipped (already there; re-run with --force to overwrite):"; printf '  %s\n' "${SKIPPED[@]}"; }
if [ "$CLAUDE_HOOK" = manual ]; then
  echo; echo "Your .claude/settings.json already exists. Add this PreToolUse hook to it:"
  echo '  { "matcher": "Edit|Write|MultiEdit", "hooks": [ { "type": "command", "command": "node scripts/branch-guard.mjs" } ] }'
fi

echo
echo "Next:"
echo "  1. Fill in the <placeholders> in AGENTS.md."
echo "  2. Commit on a branch named like feature/$PREFIX-1-agent-governance and open a pull request."
if [ "$PLATFORM" = github ]; then
  echo "  3. After it merges, make \"Agent governance\" a required status check on main"
  echo "     (Settings > Rules or Branches)."
else
  echo "  3. Add pipelines/agent-governance.yml as a pipeline and make it a Build Validation branch"
  echo "     policy on main. Allow scripts to access the OAuth token."
fi
[ "$HOOKS" -eq 0 ] || echo "  4. Wire the local hooks: pre-commit runs 'bash scripts/git-health.sh --check', pre-push runs 'bash scripts/pre-push.sh'."
