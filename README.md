# Agent governance kit

A tested kit for governing AI coding agents in a small team: written rules, local hooks, CI gates,
human approval and an incident feedback loop, from ticket to merge.

- **The practice:** [`docs/governed-agentic-delivery.md`](docs/governed-agentic-delivery.md) covers
  principles, the five control layers, worked examples, results, pitfalls and what to do next.
- **The shareable paper:** [`docs/whitepaper/index.html`](docs/whitepaper/index.html) has the same
  material as a standalone page, with every boilerplate inline. It contains no organisation-specific
  detail.

Every script has tests: `tests/run-tests.sh` runs 78 pass/fail cases in a throwaway repository, and
CI runs them plus ShellCheck on every push. The two CI definitions parse and call only those scripts,
but haven't yet run on a live GitHub or Azure DevOps project. Run each once on a test pull request
before making it a required check.

## What's in it

| Layer | File | What it does |
|---|---|---|
| Rules | [`templates/AGENTS.md`](templates/AGENTS.md) | Root agent instructions: goal, scope, non-negotiables, landmines, where things are |
| Rules | [`templates/agent-rule.md`](templates/agent-rule.md) | One topic rule or lesson per file, with its reason and the check that enforces it |
| Rules | [`templates/best-effort-decision.md`](templates/best-effort-decision.md) | Decide now, queue for professional review, never fake a sign-off |
| Rules | [`templates/shared-resource-coordination.md`](templates/shared-resource-coordination.md) | Message sessions send before using machine-wide test resources |
| Rules | [`routing/model-routing.example.json`](routing/model-routing.example.json) | Model tier per kind of work; halt and ask on a mismatch |
| Hooks | [`hooks/branch-guard.mjs`](hooks/branch-guard.mjs) | Blocks agent edits on `main`/`master`/`release` |
| Hooks | [`hooks/git-health.sh`](hooks/git-health.sh) | Detects and repairs a torn `.git/HEAD` from concurrent writers |
| Hooks | [`hooks/pre-push.sh`](hooks/pre-push.sh) + [`hooks/pre-push-checks/`](hooks/pre-push-checks/) | Frozen runner over a folder of one-file-per-check scripts |
| CI | [`scripts/work-item-guard.sh`](scripts/work-item-guard.sh) | Branch or title must carry a work-item key; the only opt-out is a label |
| CI | [`scripts/closure-keys.mjs`](scripts/closure-keys.mjs) | Only an explicit `Closes KEY` line closes a work item; `Part of KEY` just comments |
| CI | [`scripts/ci-tier.mjs`](scripts/ci-tier.mjs) | Lighter-CI labels are requests; the diff decides |
| CI | [`scripts/review-gate.sh`](scripts/review-gate.sh) + [`scripts/count-approvals.mjs`](scripts/count-approvals.mjs) | Second reader for agent-authored or high-risk changes, keyed on paths, not only on author |
| CI | [`scripts/verify-rule-refs.mjs`](scripts/verify-rule-refs.mjs) | Fails when a rule names a script, package command or CI job that doesn't exist |
| CI | [`scripts/check-catalogue.mjs`](scripts/check-catalogue.mjs) | Fails when a new shared component or function isn't in its catalogue |
| CI | [`ci/github/agent-governance.yml`](ci/github/agent-governance.yml) · [`ci/azure-pipelines/agent-governance.yml`](ci/azure-pipelines/agent-governance.yml) | Runs the gates as required checks |
| Loop | [`templates/PULL_REQUEST_TEMPLATE.md`](templates/PULL_REQUEST_TEMPLATE.md) | Closure lines, risk flags, "new rule, lesson or check added" |
| Loop | [`templates/session-handoff.md`](templates/session-handoff.md) | One handoff note per session, merged with the code |

## Adopting it in a repo

Do these in order. The first four give the most protection for the least effort.

1. Copy `templates/AGENTS.md` to the repo root as `AGENTS.md` and fill it in.
2. Copy `hooks/branch-guard.mjs` to `scripts/`, and wire it to your agent tool's pre-edit hook. A
   non-zero exit blocks the edit. For tools that use a JSON hook config, the shape is usually:
   ```json
   { "hooks": { "PreToolUse": [ { "matcher": "Edit|Write|MultiEdit",
       "hooks": [ { "type": "command", "command": "node scripts/branch-guard.mjs" } ] } ] } }
   ```
3. Copy `scripts/` to `scripts/agent-governance/`, and the CI definition for your platform from
   `ci/`. Make each job a required check on `main`. Set `WORK_ITEM_PREFIX`, and `HIGH_RISK_PATHS` if
   the defaults don't fit.
4. `verify-rule-refs.mjs` runs in that CI definition, so from day one no rule can claim a check that
   doesn't exist.
5. Copy `hooks/git-health.sh` and `hooks/pre-push.sh` to `scripts/`, and `hooks/pre-push-checks/` to
   the repo root. Wire them with your hook manager, e.g. Husky:
   `.husky/pre-commit` runs `bash scripts/git-health.sh --check`, and `.husky/pre-push` runs
   `bash scripts/pre-push.sh`.
6. Add the PR template, `templates/session-handoff.md` as `memory-bank/sessions/README.md`, and
   `catalogues.json` with `check-catalogue.mjs` once you have shared components worth cataloguing.

Keep the tests with any copy you change. `tests/run-tests.sh` reads the scripts from `KIT_SCRIPTS`
and `KIT_HOOKS` (default: this kit's `scripts/` and `hooks/`), so a copy laid out the same way can
be tested in place. Add a case whenever you change a script.

## Configuration

| Variable | Used by | Default |
|---|---|---|
| `WORK_ITEM_PREFIX` | work-item guard, closure parser | `PROJ` (keys like `PROJ-123`) |
| `OPT_OUT_LABEL` | work-item guard | `governance` |
| `AUTOMATION_BRANCHES` | work-item guard | dependabot, renovate, release-please branches |
| `HIGH_RISK_PATHS` | review gate | migrations, auth, billing, signed records, CI definitions for every supported platform, governance scripts, hooks, CODEOWNERS |
| `AGENT_BRANCH_PATTERN`, `AGENT_FOOTER_PATTERN` | review gate | `^(agent\|ai)/`; `generated (with\|by) ` |
| `DOCS_PATHS`, `ALWAYS_FULL_PATHS`, `LIGHT_MAX_FILES` | CI tier | docs/markdown; security paths, CI definitions, governance scripts, manifests and lockfiles; 25 |
| `RULE_DOCS`, `CI_DIRS`, `PATH_ROOTS` | rule-reference verifier | `AGENTS.md,rules,.agents/rules`; common CI folders |
| `BASE_REF`, `PRE_PUSH_CHECKS_DIR` | pre-push runner | `origin/main` (fails closed if missing: fetch it or set this), `pre-push-checks` |
| `CATALOGUE_CONFIG` | catalogue check | `catalogues.json` |

**Trackers.** The closure parser and work-item guard handle Jira-style keys (`PROJ-123`). With
GitHub Issues (`#123`) or Azure Boards (`AB#123`), keep the platform's native linking and turn those
two jobs off. The other gates don't depend on the tracker.

## Tamper resistance

A gate that runs code from the pull request it's judging can be switched off by that pull request.
Both CI definitions avoid this:

- **Trusted gate code.** The gate scripts run from a checkout of the base (target) branch. The PR
  checkout is only data: the diff and the rule files. A PR that changes a gate is judged by the old
  gate. On the first PR that introduces the kit there's nothing to trust yet, so that run uses the
  PR's copy and says so in a warning.
- **Gate changes are high-risk.** The default high-risk and always-full paths include the governance
  scripts, hooks and every supported CI location (`.github/`, `ci/`, `pipelines/`,
  `.azure-pipelines/`, `azure-pipelines.yml`, `.gitlab-ci.yml`, `CODEOWNERS`). A change to any of
  them needs a second reader and can't ride a lighter CI tier.
- **Approvals are tied to the head commit.** On GitHub, an approval counts only if it was given on the
  PR's current head commit, so pushing after an approval needs a fresh one. On Azure Repos votes
  aren't per-commit, so turn on "Reset all approval votes when there are new changes".
- **Back it up natively.** Add CODEOWNERS (GitHub) or a required, path-filtered "Automatically included
  reviewers" policy (Azure Repos) on `scripts/agent-governance/` and the CI definitions, and make the
  gate job a required check.

## Testing the kit

```bash
bash tests/run-tests.sh
```

This needs bash, git and Node 18+. It builds a throwaway repository in a temp dir, installs the kit
the way a consuming repo would, and runs every script against pass and fail cases.

## Keeping copies in step

This kit is the source for the scripts. If you keep a copy in an organisation standards repo, copy
changes from here and re-run the tests there, rather than editing the copy.
