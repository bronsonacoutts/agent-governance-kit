# Agent governance kit

[![Test kit](https://github.com/bronsonacoutts/agent-governance-kit/actions/workflows/test.yml/badge.svg)](https://github.com/bronsonacoutts/agent-governance-kit/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Rules an AI agent can ignore aren't governance. This kit makes them mechanical.**

Hooks, CI gates, templates and coordinator playbooks for governing AI coding agents from ticket to
merge. Extracted from a two-engineer team that ships roughly three in four of its pull requests
through agent sessions. The scripts are plain bash and Node 18+ and gate the pull request, so they
apply to any agent (or human) that opens one. The coordinator roles assume an agent tool with
named sessions and session-to-session messaging; they were developed on Claude Code.

```text
$ HEAD_REF=agent/fix-login PR_TITLE="Fix login" bash scripts/work-item-guard.sh
::error::No PROJ-<n> key in branch 'agent/fix-login' or the PR title.
exit=1
```

More blocked-PR examples in [`docs/demo.md`](docs/demo.md).

## Who it's for

| If you are... | You probably have this problem | The kit gives you |
|---|---|---|
| **A small team or solo dev leaning on coding agents** | Output outruns review. Nobody can read 50+ PRs a week line by line. | Gates that check the boring things for you, so human attention goes to judgement. |
| **An engineering lead rolling agents out to a team** | Every dev prompts differently; "please follow the rules" isn't enforceable. | One `AGENTS.md` pattern plus CI checks that fail when the rule is broken. |
| **A regulated or audit-sensitive shop** (health, safety, finance, legal) | You must show who changed what, why, and who approved it, years later. | Work-item traceability on every change, explicit closure lines, approvals tied to the exact commit. |
| **A platform / DevEx / security engineer** | Agents can edit CI config, hooks and the gates themselves. | Gates that run from the base branch, so a PR can't switch off the check judging it. |
| **Someone running many agent sessions in parallel** | Two sessions edit the same migration; every PR re-runs the full CI suite. | Merge Trains and Dispatch coordinator roles: one scheduler, claimed files, one CI run per batch. |

## Problems it solves

| Problem you'll recognise | What fixes it here |
|---|---|
| Agent pushes straight to `main` | `hooks/branch-guard.mjs` blocks the edit |
| PR with no ticket, so no audit trail | `work-item-guard.sh`; the only opt-out is a visible label |
| A ticket auto-closes because someone wrote "fixes PROJ-9" in passing | `closure-keys.mjs`: only an explicit `Closes KEY` line closes |
| "Lighter CI" label quietly skips tests on a risky change | `ci-tier.mjs`: the label is a request, the diff decides |
| Agent-written PR merges with no second reader | `review-gate.sh`: keyed on risky paths and agent authorship |
| Stale approval survives a new push | `count-approvals.mjs`: only approvals on the current head count |
| A PR edits the gate that's judging it | Gates run from the base branch; gate files are high-risk paths |
| Written rules that point at checks that don't exist | `verify-rule-refs.mjs` fails the build |
| Same review nit comes back every week | `agent-rule.md` + the "close the loop" step turn it into a check |
| Parallel sessions corrupt `.git/HEAD` | `git-health.sh` detects and repairs it |
| Merge queue is a human with a spreadsheet | [`templates/roles/`](templates/roles/): Merge Trains and Dispatch |

## Try it in two minutes

```bash
git clone https://github.com/bronsonacoutts/agent-governance-kit && cd agent-governance-kit
bash tests/run-tests.sh                      # 89 pass/fail cases in a throwaway repo
HEAD_REF=agent/fix-login PR_TITLE="Fix login" bash scripts/work-item-guard.sh   # blocked
HEAD_REF=fix/PROJ-42-login PR_TITLE="Fix login" bash scripts/work-item-guard.sh # passes
```

Then follow [Adopting it in a repo](#adopting-it-in-a-repo).

## Provenance and honesty

- **Where it came from.** Extracted from the working practice of a two-person team building a
  regulated-domain SaaS product, where agents write most of the code. The scripts, hooks, templates
  and the two coordinator playbooks are generalised from that daily use. Nothing here is a thought
  experiment.
- **What's tested here.** Every script has tests: `tests/run-tests.sh` runs 89 pass/fail cases in a
  throwaway repository, and CI runs them plus ShellCheck on every push.
- **What isn't proven yet.** The two shipped CI definitions (`ci/github/`, `ci/azure-pipelines/`)
  are generalised ports of the pipelines the team runs. They parse and call only the tested
  scripts, but this public copy hasn't yet been run as a required check on a fresh project. Run each
  once on a test pull request before requiring it.
- **The numbers.** Figures in the paper are one team's own measurements over one month, not a
  benchmark. See the note under [Results](docs/governed-agentic-delivery.md#results).

## Read more

- **The practice:** [`docs/governed-agentic-delivery.md`](docs/governed-agentic-delivery.md) is the
  canonical write-up: principles, the five control layers, worked examples, results, pitfalls and
  what to do next.
- **The shareable paper:** [`docs/whitepaper/index.html`](docs/whitepaper/index.html) is the same
  material as one standalone page for sending to someone who won't clone a repo. If the two ever
  differ, the Markdown wins.
- **Coordinator roles:** [`templates/roles/`](templates/roles/) for running many sessions at once.

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
| Roles | [`templates/roles/merge-trains.md`](templates/roles/merge-trains.md) | One scheduler session: decides merge order and file ownership, batches frozen PRs into one CI run, merges on green |
| Roles | [`templates/roles/dispatch.md`](templates/roles/dispatch.md) | One planner session: backlog hygiene, conflict-aware briefs, human-approved task chips |

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
   The runner checks the branch you have checked out. A push that includes any other branch or
   commit is refused, because the checks read the working tree and can't vouch for it.
6. Add the PR template, `templates/session-handoff.md` as `memory-bank/sessions/README.md`, and
   `catalogues.json` with `check-catalogue.mjs` once you have shared components worth cataloguing.
7. Once you routinely run three or more agent sessions at once, copy `templates/roles/` to
   `.agents/roles/` and start one Merge Trains and one Dispatch session. See its
   [README](templates/roles/README.md).

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

## About

Created and maintained by [Bronson Coutts](https://github.com/bronsonacoutts). The practice was
developed while building production software with AI agents; this kit is a generalised extraction,
released under the [MIT licence](LICENSE) as a personal open-source project. The products it was
developed on are proprietary and are not part of this repository; no code, data or configuration
from them is included. Issues and pull requests are welcome: see [CONTRIBUTING.md](CONTRIBUTING.md).
