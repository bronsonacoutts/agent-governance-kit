# Contributing

Thanks for helping. The kit's value is that every control is checked, so contributions are held to
that bar.

## Ground rules

1. **Every script change comes with a test case** in `tests/run-tests.sh`. A bug fix needs a case that
   fails before the fix and passes after.
2. **Every new rule names its check.** If you add guidance to a template, say which script enforces
   it, or mark it explicitly as advice. `scripts/verify-rule-refs.mjs` fails on a rule that points at
   something that doesn't exist.
3. **Fail closed.** When a gate can't decide (missing base ref, unparseable input), it fails. Don't
   add a silent pass.
4. **No organisation-specific detail**: no real ticket keys, hostnames, people or paths. Use `PROJ`,
   `<REPO>` and placeholders.
5. **Keep it dependency-free.** Bash, git and Node 18+ only.

## Before you open a PR

```bash
bash tests/run-tests.sh
find . -path ./.git -prune -o -name '*.sh' -print0 | xargs -0 shellcheck
```

Both must pass. Use a branch name and PR title with a work-item style key if you can; this repo
follows its own rules where it makes sense.

## Reporting a bypass

Don't file it publicly. See [SECURITY.md](SECURITY.md).
