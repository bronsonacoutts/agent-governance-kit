# Demo: gates blocking a bad pull request

Real output from the scripts in this repo, no mocking. Reproduce with the commands shown, from the
repo root. Default work-item prefix is `PROJ`; set `WORK_ITEM_PREFIX` for yours.

## 1. An agent branch with no work item

The common failure: an agent opens `agent/fix-login` and nothing links it to a ticket. Exempting
`agent/*` branches is the usual way this slips through, so the guard deliberately doesn't.

```text
$ HEAD_REF=agent/fix-login PR_TITLE="Fix login" bash scripts/work-item-guard.sh
::error::No PROJ-<n> key in branch 'agent/fix-login' or the PR title.
Rename the branch to <type>/PROJ-<n>-<slug>, or add the 'governance' label if this is
internal tooling or docs work with no product work item.
exit=1
```

Fix the branch name and it passes:

```text
$ HEAD_REF=fix/PROJ-42-login PR_TITLE="Fix login" bash scripts/work-item-guard.sh
Work-item key found: OK
exit=0
```

## 2. A key mentioned, but no explicit closure

Only a `Closes KEY` line closes a ticket; `Part of KEY` just comments. A passing mention can't close
anything.

```text
$ printf 'Fixes the login bug\n' | node scripts/closure-keys.mjs --mode=guard \
    --branch=fix/PROJ-42-login --title="Fix login"
PROJ-42 is in the branch or title but has no "Closes" or "Part of" line.
exit=1
```

## 3. A "docs only" label on a PR that touches CI

A tier label is a request, never a grant. The diff decides.

```text
$ printf 'README.md\n.github/workflows/build.yml\n' | node scripts/ci-tier.mjs --requested=docs
Requested "docs", but these need the full suite:
  .github/workflows/build.yml
tier=full
exit=1
```

## Why this matters

Each of these is a way a prose rule fails with an agent: "always link a ticket", "only close what you
finish", "use the light CI for small changes". The scripts make the rule a failing check, so the
agent finds out before a human has to.
