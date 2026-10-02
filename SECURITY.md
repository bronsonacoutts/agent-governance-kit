# Security policy

This kit is a set of controls that other people rely on to stop bad changes, so a bypass in one of
its gates is a security issue, not just a bug.

## Reporting a vulnerability

Please **don't open a public issue** for a bypass. Use either:

- GitHub's private reporting: **Security → Report a vulnerability** on this repository; or
- if you can't use that, open a [Discussion](https://github.com/bronsonacoutts/agent-governance-kit/discussions) asking for a private contact, without any detail of the bypass.

Include the script or CI definition, the input that gets past it (a branch name, PR title, label,
file list or approval sequence is usually enough), and what you expected to be blocked.

You'll get an acknowledgement within 5 working days. Fixes ship with a test case that fails before
the fix and passes after it.

## What counts

In scope: any way for a pull request, branch name, title, body, label, file path or approval
sequence to make a gate pass when it should fail, to run attacker-controlled code in the gate, or to
switch a gate off from inside the PR it judges.

Out of scope: weaknesses in the example `AGENTS.md` wording, and the behaviour of the platforms
(GitHub, Azure DevOps) themselves.

## Supported versions

The latest tagged release and `main`.
