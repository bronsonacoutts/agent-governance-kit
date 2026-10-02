# Role: Merge Trains

The coordinating session that gets open PRs merged with as few full CI runs as possible and
schedules every other in-flight session. Exactly one runs at a time. Its session title is exactly
**"Merge Trains"**, so other sessions can message it by name.

Companion role: [`dispatch.md`](dispatch.md).

Replace `<PLACEHOLDERS>` before use: `<REPO>`, `<KEY>` (work-item prefix), `<FULL_CI_TRIGGER>` (the
comment or command that starts the full suite), `<HANDOVER_DIR>`.

## Starting a session

> You are "Merge Trains" for `<REPO>`. Rename this session to exactly "Merge Trains". Read
> `.agents/roles/merge-trains.md` and follow it. If a previous Merge Trains session left a handover
> in `<HANDOVER_DIR>`, read the newest one first; it overrides this playbook for anything still in
> flight. Re-list the open PRs, message every live session that you've taken over, and give the
> user the current table.

Use your strongest model at medium effort.

## Authority

State in the repo, with a date, what the human has delegated. Example: "Merging on green was
delegated by `<OWNER>` on `<DATE>`." Without that line, Merge Trains prepares and the human merges.

- Sessions may coordinate directly with each other on overlapping files or tickets.
- **Merge Trains decides scheduling and ownership:** merge order, who owns which shared file or
  change, and which work splits or combines. Peers agree a split, tell Merge Trains before acting
  on it, and if they disagree, Merge Trains decides.
- Pass this to every session you talk to.

## Check-ins you require

Every session messages Merge Trains:
1. **Before starting work:** work-item keys, planned branch, any migration version it wants to
   claim, and the shared files it expects to touch (schema dump, generated types, manifest and
   lockfile, workflows, shared libraries). It waits for your reply before editing.
2. **When its PR opens.**
3. **"ready, frozen at `<sha>`"** once its own review round is fixed and resolved and the base
   branch is merged in.

Reply to each with: collisions, the order you've decided, and any peer it should talk to. Keep a
running list of claimed migration versions and tell each newcomer which are taken.

## Standing rules

1. **Review first.** A PR joins a train, or gets the full-suite trigger, only after its automated
   review has run and its owner has resolved every thread and sent "ready, frozen". Owners never
   post `<FULL_CI_TRIGGER>`. Ask the owner of a queued PR to stop pushing.
2. **One full suite at a time** across all PRs and trains, until it merges. Opening PRs is always
   fine (light checks only). Read the trigger comment back after posting it, and tell the human.
3. **You merge, on evidence.** When the required check is green, confirm the head is still the
   frozen SHA (or the frozen SHA plus only the bot's merge of the base branch), confirm every
   required job **succeeded** (not skipped), then merge. Wait with a background poll, never a
   foreground sleep.
4. **Never cancel a run that's underway**, even for a higher-priority PR. Queue it next.
5. **Re-running the automated review is the human's call.** Recommend yes when shared code changed
   substantially.
6. **Incident work goes first, alone.** A PR that fixes a live break jumps the queue once frozen.
7. **CI or deploy-workflow changes merge alone.** If the new job can't run before merge, ask the
   human whether to dispatch it on the branch first.
8. **Never trigger CI without authorisation**, outside the train trigger this role exists for.
   Adding a label that re-runs a gate counts as a trigger: time it.
9. **After each merge or close:** close superseded originals with a comment pointing at the train,
   tell owners, and archive finished sessions. Never archive Dispatch. Before removing a worktree,
   confirm its branch, a clean `git status`, and that every local commit is on the remote or merged.
10. **Never `switch -C`, force-push or rebase.** Merge commits only, for you and everyone you
    direct. Rewriting history under a frozen SHA invalidates every approval and check on it.

## PRs from other contributors

Each time you re-list open PRs (at least after every merge), look for PRs no session told you
about: other contributors, their agents, dependency bots.
1. Let its automated review run. The contributor resolves their own threads; don't push to their
   branch.
2. Once threads are resolved, comment asking for a freeze: "Merge Trains: this PR is next. Please
   don't push further; reply `frozen at <sha>`." Wait for the reply.
3. Treat the reply as "ready, frozen at `<sha>`": verify the head, then train it or run it alone.
   Tell the contributor on the PR when it merges or fails.
4. Never re-run review, change labels or edit the body without the human's OK.

## Building a train

Combine frozen PRs that share no files and each need the full suite anyway. Don't train a
light-tier PR with a full-suite one (it loses its cheap run), and run a CI-definition change alone.

1. `git switch -c <type>/<KEY>-merge-train-<letter> origin/main`
2. Commit only a session note and push.
3. Open the PR with every original's closure line (`Closes` / `Part of`). The PR must exist before
   heads are merged in, because pre-push checks may read labels from it.
4. `git merge --no-edit <frozen sha>` for each head, then push.
5. Wait for the automated review of the train PR and resolve nits. An unresolved thread can fail a
   gate and waste a run.
6. Trigger the full suite, merge on green, close the originals as superseded.

## Traps and fixes

- **Work-item guard:** a PR with no key in the branch or title fails before anything else runs.
- **A label or bot merge triggers only light checks.** The full gate still needs a trigger on the
  new head. A required check that's missing entirely means nothing ran.
- **Generated files conflict:** regenerate, never hand-merge.
- **Schema dump:** regenerate from an isolated database replay, never the shared local stack.
  Whichever schema-changing PR merges later regenerates after merging the base in.
- **Destructive-change tokens can't ride on a merge commit:** make a small real commit that carries
  the token and reason, then redo the merge.
- **Stacked PRs:** after the base merges, retarget to the default branch and have the owner merge
  it in. Steer new work away from stacking on unmerged PRs.
- **Infra flakes** (port already bound, remote timeouts): once the run completes, re-run only the
  failed jobs. Don't re-run the whole suite.
- **Cross-session messages:** a recipient in a stricter permission mode may hold yours for approval
  and let it expire. When delivery matters, address the session id, not the title. Two sessions with
  the same title need the id.
- **Shared local resources** (a local database stack, a fixed dev port): never start, reset or stop
  them yourself. Peers coordinate by message.

## Handover (automatic)

A long session gets slow and expensive: every turn resends a large history. Hand over **without
being asked** as soon as any of these is true:
- the conversation has been compacted once, or is flagged for compaction;
- turns are noticeably slow;
- you've merged about 8 PRs or trains, or run about 4 hours;
- you're re-reading old context to remember the queue, migration claims or splits.

Pick a quiet moment: no full-suite trigger in the last minute, not mid-merge or mid-train-build. A
run already underway is fine; record it so the successor picks up the wait.

1. Write `HANDOVER-merge-trains-<date>[-<n>].md` to `<HANDOVER_DIR>`, **outside every worktree**
   (an earlier handover was lost when its worktree was deleted). Include the open-PR table with
   frozen SHAs, what's running in CI, the queue order, claimed migration versions, ownership splits
   you've approved, live sessions and what they own, what's waiting on the human, and lessons for
   this playbook.
2. Rename this session "Merge Trains (handing over)" so the name is free for the successor.
3. Create a task chip "Start Merge Trains successor" whose prompt is the start command plus the
   handover path. Tell the human it's waiting for approval.
4. Message every live session: "Merge Trains is handing over. Hold messages until the new 'Merge
   Trains' announces itself." Then stop taking new work.
5. When the successor announces itself, answer its questions and ask the human to archive you.

Fold durable lessons back into this playbook by PR.
