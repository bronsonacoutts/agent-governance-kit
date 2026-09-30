# Session handoff notes, one file per session

Copy this to `memory-bank/sessions/README.md`.

Each agent session writes its handoff as **one new file** here, committed on its own feature branch
and merged inside the feature PR. Two sessions never write the same file, so handoffs can't
conflict, however many agents branch off the same base.

Use this instead of prepending entries to `../activeContext.md` and `../progress.md`. When every
session prepends to those two files, any two open PRs conflict. Keep them for slow-changing
context (current phase, key decisions), updated rarely and deliberately.

## Reading

At the start of a session, read `../projectbrief.md` and the newest few notes here, including notes
on open branches that haven't merged yet:

```bash
ls -1 memory-bank/sessions/*.md | grep -v README | sort | tail -10
git for-each-ref --format='%(refname:short)' refs/remotes/origin | while read -r b; do
  git diff --name-only --diff-filter=A origin/main..."$b" -- memory-bank/sessions/ 2>/dev/null
done | sort -u
```

## Writing

File name: `<YYYY-MM-DD>-<KEY>-<short-slug>.md`, e.g. `2026-09-30-PROJ-412-expired-link-message.md`.
With no work item, drop the key. If you pick the work up again later, update your own file. Don't
edit another session's file: write a new one that refers to it.

```markdown
# <KEY>: <short title>

Branch: `<type>/<KEY>-<slug>` · PR: <#number or "not opened yet">

## Done
- <What changed, in outcome terms.>

## Open / blocked
- <Follow-up, with its work-item key.>

## Watch out for
- <Parallel branches touching the same files, shared resources in use, migrations to
  re-run after a merge, anything surprising.>
```

## Archiving

When this folder gets long, move notes older than about 30 days into `archive/` in a
memory-bank-only PR. Moving whole files is the only memory-bank edit that touches shared state, so
it's rare and can't collide with new notes.
