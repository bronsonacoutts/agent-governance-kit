# Contributing

Thanks for helping. Every kind of contribution counts:

- **Questions, ideas and "here's how we use it"** go in
  [Discussions](https://github.com/bronsonacoutts/agent-governance-kit/discussions).
- **Bugs and confusing steps** go in [Issues](https://github.com/bronsonacoutts/agent-governance-kit/issues).
- **A way past a gate** is a security report, not an issue: see [SECURITY.md](SECURITY.md).
- **Code and docs** come as pull requests from a fork.

Good first pull requests: a GitLab CI definition, support for `#123`-style issue links in the two
key checks, a new pre-push check, or a clearer step in the README.

The kit's value is that every control is checked, so code contributions are held to that bar.

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

Both must pass. Fork the repo, branch, and open a pull request against `main`. One reviewer
and the `test` check are required to merge. Use a work-item style key in the branch name if you can; this repo
follows its own rules where it makes sense.

## Reporting a bypass

Don't file it publicly. See [SECURITY.md](SECURITY.md).
