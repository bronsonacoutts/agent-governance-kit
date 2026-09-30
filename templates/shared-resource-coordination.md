# Shared-Resource Coordination Message

Several agent sessions often run on one machine. Some test resources are machine-wide, not
per-worktree: the local database stack, a fixed dev or preview port, a shared remote test
environment. A suite that resets the database mid-run in another session produces failures that
look like real regressions, and a test runner that reuses an existing server on a fixed port can
silently test another worktree's build.

Before using any of these, list the other active sessions and send this to each one that might be
testing. Wait for "go" or "done". Never reset, migrate, stop or restart a shared resource that
another session is using without its go-ahead.

```text
to: <each active session that might be testing>

I'm about to use: <local database stack | the preview port | shared test env>
For: <what, e.g. the full test suite, which resets app tables>
Expected duration: <~N min>
Is anything of yours running against it? I'll wait for "go" or "done".

--- when finished ---
Done with <resource>. It's free.
```
