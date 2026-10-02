# Coordinator roles

Two playbooks for running many AI coding sessions against one repository without them colliding,
duplicating work or burning CI.

A **rule** (`AGENTS.md`, `.agents/rules/`) applies to every session. A **role** is a job exactly one
session holds at a time, named so other sessions can message it.

| Role | Job | Playbook |
|---|---|---|
| Merge Trains | Schedules every in-flight session, decides file ownership and merge order, batches frozen PRs into one CI run, merges on green | [`merge-trains.md`](merge-trains.md) |
| Dispatch | Turns the backlog into small, conflict-aware session briefs a human approves | [`dispatch.md`](dispatch.md) |

## When you need them

One agent session needs neither. Reach for these when you routinely have **three or more sessions
open at once** and see any of: two PRs editing the same migration or lockfile, a full CI suite
re-run per PR, duplicate tickets for the same fix, or a human acting as the merge queue.

## How they fit the kit

- Work sessions check in with Merge Trains before editing, when the PR opens, and when it is
  frozen. The brief template in `dispatch.md` carries the exact wording.
- The CI gates in `scripts/` stay the enforcement layer. These roles are the *coordination* layer
  above them: they decide order, the gates decide whether a change is allowed in.
- Humans keep every irreversible action. Merge Trains merges only on green and only where the owner
  has delegated that; Dispatch never merges or triggers CI.

## Requirements

An agent tool where sessions have names other sessions can message, and where a session can propose
a new session for a human to approve (Claude Code calls these task chips). The playbooks were
developed on Claude Code; the protocol itself (check in, freeze, one full CI run, hand over) is
tool-neutral.

## Adopting

1. Copy this folder to `.agents/roles/` and replace every `<PLACEHOLDER>`.
2. Add a start command per role (a Claude Code skill or slash command that renames the session and
   loads the playbook).
3. Choose a handover directory **outside** every worktree and set `HANDOVER_DIR`.
4. Run each role on your strongest model at medium effort. The work is judgement, not volume.

## Status

Extracted from a working setup and generalised. The playbooks are tested in practice, not by the
kit's `tests/run-tests.sh`: they are prose, not scripts. Mechanical steps (train assembly, readiness
check, CI wait) are still done by hand and are good candidates for scripts.
