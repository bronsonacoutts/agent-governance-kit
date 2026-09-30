#!/usr/bin/env bash
# Tests for the agent-governance kit. Builds a throwaway git repo (with a local bare remote) in a
# temp dir, installs the kit's scripts into it the way a consuming repo would, and runs each script
# against pass and fail cases.
#
# usage: bash tests/run-tests.sh
# needs: bash, git, node 18+
# The Markdown fixtures below contain literal backticks on purpose, so single quotes are correct.
# shellcheck disable=SC2016
set -uo pipefail
KIT="$(cd "${KIT_SCRIPTS:-$(dirname "$0")/../scripts}" && pwd)"
HOOKS="$(cd "${KIT_HOOKS:-$(dirname "$0")/../hooks}" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------- scratch repo
git init -q --bare "$WORK/origin.git"
git init -q -b main "$WORK/repo"
cd "$WORK/repo" || exit 1
git config core.autocrlf false; git config core.longpaths true
git config user.email test@example.com; git config user.name test
git remote add origin ../origin.git
mkdir -p scripts/agent-governance pre-push-checks .github/workflows rules docs src/ui server/functions/send-thing server/functions/_shared
cp "$KIT"/*.mjs "$KIT"/*.sh scripts/agent-governance/
cp "$HOOKS/branch-guard.mjs" "$HOOKS/git-health.sh" "$HOOKS/pre-push.sh" scripts/
cp "$HOOKS/pre-push-checks/example-pipe-hides-exit-code.sh" pre-push-checks/
echo '{"name":"t","scripts":{"test":"echo t","lint":"echo l"}}' > package.json
echo "# scratch" > README.md
git add -A && git commit -qm init && git push -q origin main

PASS=0; FAIL=0
expect() { # expect <0|N|exit-code> <label> <cmd...>
  local want="$1" label="$2"; shift 2
  local out got; out="$("$@" 2>&1)"; got=$?
  if { [ "$want" = N ] && [ "$got" != 0 ]; } || [ "$want" = "$got" ]; then
    PASS=$((PASS+1)); echo "  ok    $label"
  else
    FAIL=$((FAIL+1)); echo "  FAIL  $label: want $want, got $got"; printf '%s\n' "$out" | sed 's/^/          /'
  fi
}
expect_out() { # expect_out <want-stdout> <label> <cmd...>
  local want="$1" label="$2"; shift 2
  local out; out="$("$@" 2>/dev/null)"
  if [ "$out" = "$want" ]; then PASS=$((PASS+1)); echo "  ok    $label"
  else FAIL=$((FAIL+1)); echo "  FAIL  $label: want '$want', got '$out'"; fi
}
G=scripts/agent-governance

echo "branch-guard.mjs"
expect 2 "blocks edits on main" node scripts/branch-guard.mjs
git switch -q -c feature/PROJ-1-x
expect 0 "allows edits on a feature branch" node scripts/branch-guard.mjs
git switch -q main

echo "git-health.sh"
expect 0 "healthy HEAD passes --check" bash scripts/git-health.sh --check
printf 'ref: refs/heads/main\n\0\0\0\0' > .git/HEAD
expect N "HEAD with trailing NULs fails --check" bash scripts/git-health.sh --check
expect 0 "repair rewrites HEAD" bash scripts/git-health.sh
expect 0 "healthy after repair" bash scripts/git-health.sh --check
expect 0 "git works after repair" git status --short
printf '\0\0\0\0' > .git/HEAD
expect N "all-NUL HEAD: repair refuses to guess" bash scripts/git-health.sh
printf 'ref: refs/heads/main\n' > .git/HEAD
rm -f .git/HEAD.bak.*

echo "work-item-guard.sh"
wig() { HEAD_REF="$1" PR_TITLE="$2" LABELS="$3" bash $G/work-item-guard.sh; }
expect 0 "key in branch" wig feature/PROJ-12-x "t" '[]'
expect 0 "key in title" wig fix/thing "fix(PROJ-12): t" '[]'
expect 0 "refs/heads/ prefix stripped" wig refs/heads/feature/PROJ-12-x "t" '[]'
expect N "no key" wig fix/login-thing "t" '[]'
expect N "PROJ-0 rejected" wig fix/PROJ-0-x "t" '[]'
expect N "key embedded in a word rejected" wig fix/XPROJ-12-x "t" '[]'
expect N "key followed by letters rejected" wig feature/PROJ-12abc "t" '[]'
expect N "key followed by underscore rejected" wig feature/PROJ-12_x "t" '[]'
expect N "agent/* branch NOT exempt" wig agent/tidy-up "t" '[]'
expect 0 "governance label (JSON)" wig docs/x "t" '["governance","docs"]'
expect 0 "governance label (comma list)" wig docs/x "t" 'docs,governance'
expect N "similar label doesn't opt out" wig docs/x "t" '["governance-review"]'
expect 0 "dependabot branch" wig dependabot/npm/x "t" '[]'
expect 0 "custom prefix" env WORK_ITEM_PREFIX=ABC HEAD_REF=feature/ABC-9-x PR_TITLE=t LABELS='[]' bash $G/work-item-guard.sh
expect N "custom prefix rejects default key" env WORK_ITEM_PREFIX=ABC HEAD_REF=feature/PROJ-9-x PR_TITLE=t LABELS='[]' bash $G/work-item-guard.sh

echo "closure-keys.mjs"
cl() { printf '%b' "$3" | node $G/closure-keys.mjs --mode="$1" --branch="$2" --title="t"; }
expect 0 "Closes primary" cl guard feature/PROJ-318-x 'Closes PROJ-318\n\nbody'
expect 0 "Part of primary" cl guard feature/PROJ-318-x 'Part of PROJ-318\n'
expect N "Fixes / Resolves are not closing verbs" cl guard feature/PROJ-318-x 'Resolves PROJ-318\n'
expect N "title containing = keeps its key" bash -c "printf 'body\n' | node $G/closure-keys.mjs --mode=guard --branch=fix/x '--title=fix=x PROJ-12'"
expect N "undeclared primary" cl guard feature/PROJ-318-x 'body only\n'
expect N "both Closes and Part of" cl guard feature/PROJ-318-x 'Closes PROJ-318\nPart of PROJ-318\n'
expect N "hyphenated secondary mention" cl guard feature/PROJ-318-x 'Closes PROJ-318\nsee PROJ-290\n'
expect 0 "de-hyphenated secondary mention" cl guard feature/PROJ-318-x 'Closes PROJ-318\nsee PROJ 290\n'
expect 0 "extra Closes for a secondary" cl guard feature/PROJ-318-x 'Closes PROJ-318\nCloses PROJ-290\n'
expect 0 "CRLF body" cl guard feature/PROJ-318-x 'Closes PROJ-318\r\nbody\r\n'
expect_out '{"close":["PROJ-290"],"comment":["PROJ-318"]}' "close mode: closes only Closes lines, no duplicates" \
  cl close feature/PROJ-318-x 'Part of PROJ-318\nCloses PROJ-290\n'
expect 0 "custom prefix" bash -c "printf 'Closes ABC-7\n' | WORK_ITEM_PREFIX=ABC node $G/closure-keys.mjs --mode=guard --branch=feature/ABC-7-x --title=t"

echo "review-gate.sh"
rg() { AUTHOR_TYPE="$1" HEAD_REF="$2" BODY="$3" CHANGED_FILES="$4" APPROVALS="$5" bash $G/review-gate.sh; }
expect 0 "human, low-risk, no approvals" rg User feature/PROJ-1 "plain" "src/ui/button.tsx" 0
expect N "human, high-risk, no approvals" rg User feature/PROJ-1 "plain" "migrations/0001.sql" 0
expect 0 "human, high-risk, one approval" rg User feature/PROJ-1 "plain" "migrations/0001.sql" 1
expect N "bot author, no approvals" rg Bot feature/PROJ-1 "plain" "src/ui/button.tsx" 0
expect N "agent footer under a human account" rg User feature/PROJ-1 "Generated with an AI coding assistant" "README.md" 0
expect N "agent/ branch" rg User agent/PROJ-1 "plain" "README.md" 0
expect N "workflow change is high-risk" rg User feature/PROJ-1 "plain" ".github/workflows/ci.yml" 0
expect N "Azure pipeline change is high-risk" rg User feature/PROJ-1 "plain" "pipelines/ci.yml" 0
expect N "root azure-pipelines.yml is high-risk" rg User feature/PROJ-1 "plain" "azure-pipelines.yml" 0
expect N "governance script change is high-risk" rg User feature/PROJ-1 "plain" "scripts/agent-governance/review-gate.sh" 0
expect 0 "custom HIGH_RISK_PATHS" env HIGH_RISK_PATHS='^infra/' AUTHOR_TYPE=User HEAD_REF=f BODY=p CHANGED_FILES=migrations/1.sql APPROVALS=0 bash $G/review-gate.sh

echo "count-approvals.mjs"
GH_P1='[{"user":{"login":"dev-a","type":"User"},"state":"APPROVED","commit_id":"c1","submitted_at":"2026-09-01T01:00:00Z"},
{"user":{"login":"dev-a","type":"User"},"state":"CHANGES_REQUESTED","submitted_at":"2026-09-01T02:00:00Z"},
{"user":{"login":"dev-b","type":"User"},"state":"APPROVED","commit_id":"c2","submitted_at":"2026-09-01T01:30:00Z"},
{"user":{"login":"dev-b","type":"User"},"state":"COMMENTED","submitted_at":"2026-09-01T04:00:00Z"},
{"user":{"login":"author","type":"User"},"state":"APPROVED","submitted_at":"2026-09-01T01:40:00Z"},
{"user":{"login":"review-bot","type":"Bot"},"state":"APPROVED","submitted_at":"2026-09-01T01:50:00Z"}]'
GH_P2='[{"user":{"login":"dev-c","type":"User"},"state":"APPROVED","commit_id":"c1","submitted_at":"2026-09-01T03:00:00Z"},
{"user":{"login":"dev-d","type":"User"},"state":"APPROVED","submitted_at":"2026-09-01T03:00:00Z"},
{"user":{"login":"dev-d","type":"User"},"state":"DISMISSED","submitted_at":"2026-09-01T05:00:00Z"}]'
ca_gh() { printf '%s\n%s\n' "$GH_P1" "$GH_P2" | node $G/count-approvals.mjs --format=github --author=author; }
expect_out 2 "github: latest review wins; author, bots, comments and dismissals excluded" ca_gh
ca_gh_c() { printf '%s\n%s\n' "$GH_P1" "$GH_P2" | node $G/count-approvals.mjs --format=github --author=author --commit="$1"; }
expect_out 1 "github --commit: only approvals on the head commit count (c2)" ca_gh_c c2
expect_out 1 "github --commit: approvals on another commit are ignored (c1)" ca_gh_c c1
expect_out 0 "github --commit: nothing counts on a brand-new commit" ca_gh_c c9
expect_out 0 "github: empty review list" bash -c "echo '[]' | node $G/count-approvals.mjs --format=github --author=a"
ADO='{"createdBy":{"id":"u1"},"reviewers":[{"id":"u1","vote":10},{"id":"u2","vote":10},{"id":"u3","vote":5},{"id":"u4","vote":-5},{"id":"g1","vote":10,"isContainer":true},{"id":"u5","vote":0}]}'
expect_out 2 "ado: approved and approved-with-suggestions; creator and groups excluded" bash -c "echo '$ADO' | node $G/count-approvals.mjs --format=ado"

echo "ci-tier.mjs"
tier() { printf '%b' "$2" | node $G/ci-tier.mjs --requested="$1"; }
expect 0 "docs tier with docs only" tier docs 'docs/a.md\nREADME.md\n'
expect N "docs tier with code" tier docs 'docs/a.md\nsrc/x.ts\n'
expect 0 "light tier" tier light 'src/x.ts\n'
expect N "light tier touching auth" tier light 'src/auth/session.ts\n'
expect N "light tier touching a lockfile" tier light 'bun.lock\n'
expect N "light tier touching workflows" tier light '.github/workflows/ci.yml\n'
expect N "light tier touching an Azure pipeline" tier light 'pipelines/agent-governance.yml\n'
expect N "light tier touching governance scripts" tier light 'scripts/agent-governance/ci-tier.mjs\n'
expect N "light tier touching a nested lockfile" tier light 'apps/web/bun.lock\n'
expect N "docs tier touching a CI folder" tier docs '.github/workflows/README.md\n'
expect 0 "full always fits" tier full 'src/auth/session.ts\n'
expect N "unknown tier rejected" tier lite 'docs/a.md\n'
expect_out "tier=full" "--no-fail downgrades to full" bash -c "printf 'src/auth/a.ts\n' | node $G/ci-tier.mjs --requested=light --no-fail"
expect N "light tier over the file limit" bash -c "for i in \$(seq 1 26); do echo src/f\$i.ts; done | node $G/ci-tier.mjs --requested=light"

echo "verify-rule-refs.mjs"
printf 'jobs:\n  guard:\n    steps:\n      - name: Access policy guard\n        run: echo hi\n' > .github/workflows/build.yml
mkdir -p pipelines && printf 'steps:\n- bash: echo hi\n  displayName: Tenant isolation guard\n' > pipelines/ci.yml
printf 'Enforced by CI job "Access policy guard", script `scripts/agent-governance/closure-keys.mjs`, run `npm run test`.\n' > rules/database.md
expect 0 "all references resolve (no AGENTS.md needed)" node $G/verify-rule-refs.mjs
printf 'Enforced by CI step "Tenant isolation guard".\n' > rules/ado.md
expect 0 "Azure Pipelines displayName resolves" node $G/verify-rule-refs.mjs
printf 'Enforced by CI job "Schema drift guard".\n' > rules/drift.md
expect N "missing CI job" node $G/verify-rule-refs.mjs
printf 'Run `scripts/nope.sh` then `bun run nope`.\n' > rules/drift.md
expect N "missing script and package script" node $G/verify-rule-refs.mjs
printf 'A job named "Access policy guard extra" is not the same job: CI job "Access policy".\n' > rules/drift.md
expect N "partial job-name match rejected" node $G/verify-rule-refs.mjs
rm rules/drift.md rules/ado.md

echo "check-catalogue.mjs"
echo 'export const Button = 1' > src/ui/button.tsx
echo 'test' > src/ui/button.test.tsx
touch server/functions/send-thing/index.ts server/functions/_shared/util.ts
printf '# Components\n- `button`\n' > docs/component-catalogue.md
printf '# Functions\n- `send-thing`\n' > docs/function-catalogue.md
cat > catalogues.json <<'JSON'
[
  { "dir": "src/ui", "doc": "docs/component-catalogue.md", "ext": [".tsx"] },
  { "dir": "server/functions", "doc": "docs/function-catalogue.md", "dirsAreItems": true }
]
JSON
expect 0 "complete catalogues (tests and _shared skipped)" node $G/check-catalogue.mjs
echo 'x' > src/ui/date-range-field.tsx
expect N "uncatalogued component" node $G/check-catalogue.mjs
rm src/ui/date-range-field.tsx
expect N "missing config" env CATALOGUE_CONFIG=nope.json node $G/check-catalogue.mjs

echo "pre-push.sh + example check"
git switch -q -c fix/PROJ-377-t
git add -A && git commit -qm "test fixtures"
expect 0 "clean branch passes" bash scripts/pre-push.sh
printf 'jobs:\n  a:\n    steps:\n      - run: ls | head -1\n' > .github/workflows/bad.yml
git add -A && git commit -qm "bad pipe"
expect N "catches a pipe into head" bash scripts/pre-push.sh
expect 0 "empty checks folder is a no-op" env PRE_PUSH_CHECKS_DIR=nothing-here bash scripts/pre-push.sh
expect N "missing base ref fails closed" env BASE_REF=origin/nope bash scripts/pre-push.sh
git switch -q main

echo
echo "passed $PASS, failed $FAIL"
[ "$FAIL" -eq 0 ]
