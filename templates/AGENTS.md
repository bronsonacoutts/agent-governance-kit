# Agent instructions

Copy this to the repo root as `AGENTS.md` and fill it in. It's loaded into every agent session, so keep it under two screens. Put detail in topic rules
(`.agents/rules/*.md`, from [`agent-rule.md`](agent-rule.md)) and point to them.
The pattern and its rationale: `docs/governed-agentic-delivery.md` in the agent governance kit.

## Goal
<One sentence every feature decision is tested against.>

## Scope
- Canonical scope lives in `docs/product/scope.md`. If this file disagrees, that one wins.
- Build now: <list>
- Deferred: <list>
- Do not build: <list>

## Non-negotiables
- Never edit on the default branch. Create a branch first: `<type>/<KEY>-<slug>`.
- Every change that affects product behaviour needs a work-item key in its branch or title.
- Never merge, and never re-trigger CI, unless a person asked for that specific action.
- Never put a secret in a file, a command line or a transcript. Wrap commands with the secrets
  manager's CLI (`<secrets-cli> run -- <command>`).
- <Domain rules, e.g. signed records are append-only; corrections are new versions.>

## Before you finish
1. Run the pre-push review (`scripts/pre-push.sh`).
2. Check your diff against lessons marked BLOCKING in `.agents/rules/lessons/`.
3. Write your handoff note: `memory-bank/sessions/<YYYY-MM-DD>-<HHMM>-<KEY>-<slug>.md`.

## Close the loop
When you fix a review comment, ask whether a check in `pre-push-checks/` or a lesson in
`.agents/rules/lessons/` would have caught it. If so, add it in the same change.

## Decisions that need a professional
Decide on the most conservative reading of the primary source you actually read. Record the
reasoning next to the work and add an entry to that profession's review queue
([`best-effort-decision.md`](best-effort-decision.md)). Never record a sign-off
that didn't happen.

## Shared resources
Before using anything machine-wide (local database stack, a fixed dev port, a shared remote test
environment), coordinate with other active sessions
([`shared-resource-coordination.md`](shared-resource-coordination.md)).

## Landmines
- <Something that looks harmless but isn't, and what to do instead.>

## Where things are
- Topic rules: `.agents/rules/*.md` · Lessons: `.agents/rules/lessons/*.md` (one file each)
- Model routing: `model-routing.json` (see `routing/model-routing.example.json` in the kit)
- Handoff notes: `memory-bank/sessions/` (read the newest few before starting)
