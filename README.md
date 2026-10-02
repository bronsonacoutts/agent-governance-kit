# Agent governance kit

[![Test kit](https://github.com/bronsonacoutts/agent-governance-kit/actions/workflows/test.yml/badge.svg)](https://github.com/bronsonacoutts/agent-governance-kit/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Rules an AI agent can ignore aren't governance. This kit turns them into checks it can't skip.**

Hooks and CI checks for AI coding agents, from ticket to merge. One command installs them into an
existing repo. Built by a two-person team whose agents write most of its pull requests.

```text
$ HEAD_REF=agent/fix-login PR_TITLE="Fix login" bash scripts/work-item-guard.sh
::error::No PROJ-<n> key in branch 'agent/fix-login' or the PR title.
exit=1
```

## Is this for you?

**Yes, if any of these are true:**

- AI agents open pull requests in your repo.
- You can't read every agent PR line by line.
- You need to show later which ticket a change was for and who approved it.
- You run more than one agent session at a time.

**Probably not, if:**

- Humans open every PR and AI only autocompletes or chats.
- You don't use pull requests or CI.

## What it does

| Without it | With it |
|---|---|
| An agent edits `main` directly | The edit is blocked |
| A PR has no ticket | CI fails until it has one |
| "fixes PROJ-9" in passing closes a ticket | Only a `Closes PROJ-9` line closes it |
| A "light CI" label skips tests on a risky change | The diff decides the CI tier, not the label |
| An agent PR merges with nobody else reading it | Risky paths need a second reader |
| An approval survives a later push | Only approvals on the latest commit count |
| A PR switches off the check judging it | Checks run from the base branch |
| A rule names a check that doesn't exist | CI fails |
| Parallel sessions collide on the same files | One coordinator session decides who owns what |

See it block real PRs in [`docs/demo.md`](docs/demo.md).

## What it requires

- A git repo where changes reach `main` through pull requests.
- **GitHub Actions** or **Azure Pipelines**.
- **bash**, **git** and **Node 18+** (on your machine and the CI runner). No packages to install.
- Work-item keys like `ABC-123` (Jira-style). With GitHub Issues or Azure Boards links, turn off the
  two key checks; everything else still works.
- Optional: **Claude Code** for the automatic edit guard. Other agent tools can call the same
  script from their own pre-edit hook.

## What it entails

The installer only adds files. It never commits, pushes or changes settings, and it skips any file
you already have.

| Added to your repo | Why |
|---|---|
| `AGENTS.md` | Rules every agent session reads. You fill in the blanks. |
| `.claude/settings.json` | Blocks agent edits while you're on `main` (only created if you don't have one) |
| `scripts/branch-guard.mjs` | The script that hook runs |
| `scripts/agent-governance/` | The CI gate scripts |
| `.github/workflows/agent-governance.yml` or `pipelines/agent-governance.yml` | Runs the gates on every PR |
| `.github/PULL_REQUEST_TEMPLATE.md` | Closure lines and risk flags (GitHub only) |
| With `--hooks`: `scripts/git-health.sh`, `scripts/pre-push.sh`, `pre-push-checks/` | The same checks locally, before a push |
| With `--roles`: `.agents/roles/` | Merge Trains and Dispatch playbooks for many parallel sessions |

Your part afterwards: fill in `AGENTS.md`, merge the PR, and make **Agent governance** a required
check.

## Quick start

```bash
git clone https://github.com/bronsonacoutts/agent-governance-kit
bash agent-governance-kit/install.sh path/to/your-repo --prefix ABC
```

Use your tracker's key prefix for `ABC`. Then, in your repo:

```bash
git switch -c chore/ABC-1-agent-governance
git add -A && git commit -m "chore: add agent governance (ABC-1)"
git push -u origin HEAD     # open a PR with "Closes ABC-1" in the body
```

After it merges, mark **Agent governance** as a required status check on `main`. Done.

Add `--hooks` for local pre-push checks, `--roles` for the coordinator playbooks, and
`--platform azure` if auto-detection picks the wrong CI. Re-running is safe.

## Contributing

This kit gets better every time someone finds a way past a gate. Ways to help, from smallest up:

- ⭐ **Star the repo** if it's useful. It helps others find it.
- 💬 **Say how you use it** in [Discussions](https://github.com/bronsonacoutts/agent-governance-kit/discussions): your stack, your agent tool, what broke.
- 🐛 **Open an [issue](https://github.com/bronsonacoutts/agent-governance-kit/issues)** for a bug, a confusing step or a missing platform.
- 🔧 **Send a pull request.** Fork, add a test case to `tests/run-tests.sh`, and open a PR. Good
  first contributions: a GitLab CI definition, support for `#123`-style issue links, more
  pre-push checks.
- 🔒 **Found a way past a gate?** Report it privately: see [SECURITY.md](SECURITY.md).

Read [CONTRIBUTING.md](CONTRIBUTING.md) first. It's short.

## Provenance and honesty

- **Where it came from.** Extracted from the working practice of a two-person team building a
  regulated-domain SaaS product, where agents write most of the code. The scripts, hooks, templates
  and the two coordinator playbooks are generalised from that daily use. Nothing here is a thought
  experiment.
- **What's tested here.** Every script and the installer have tests: `tests/run-tests.sh` runs over
  100 pass/fail cases in throwaway repositories, and CI runs them plus ShellCheck on every push.
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
| Setup | [`install.sh`](install.sh) | Installs the kit into an existing repo; adds files only, never overwrites |
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

## Manual setup

[`install.sh`](install.sh) does steps 1 to 3, and 5 and 7 with `--hooks` and `--roles`. To do
it by hand, follow these in order. The first four give the most protection for the least effort.

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
from them is included.
