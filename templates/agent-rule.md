---
# Use this template for both kinds of agent rule:
#   - a topic rule (.agents/rules/<topic>.md): standing guidance for an area of the repo
#   - a lesson (.agents/rules/lessons/<KEY>-<slug>.md): one recurring error per file, written in
#     the same change as the fix. One file per lesson means parallel PRs never conflict.
severity: BLOCKING | BUILD RISK | LOGIC | HYGIENE
work_item: <KEY>
date: <YYYY-MM-DD>
enforced_by: <pre-push-checks/<file>.sh | CI job "<exact job name>" | none (judgement)>
---

# Agent Rule: [Short Descriptive Title]

> **Context**: Briefly describe the environment, tool, or scenario this rule applies to (e.g., PowerShell on Windows, database migrations, the issue tracker API).

## The Limitation / Recurring Error
Describe the problem that triggered the creation of this rule. Say what someone would actually see,
and copy the error text if there is one.
*Example: The agent repeatedly attempted to use `grep` in PowerShell, which resulted in a missing cmdlet error.*

## Why It Matters
The incident or risk behind the rule: what happened, what it cost, and the work item. A rule that
names its reason survives the next refactor. A bare "never do X" gets optimised away by the first
agent that finds it inconvenient.

## The Rule / Correct Behavior
Provide the explicit instruction for how the agent must handle this scenario in the future.
*Example: **Never use `grep` in PowerShell**. You **MUST** use the native `grep_search` tool instead. If a terminal search is strictly required, use `Select-String`.*

## How It's Enforced
Name the check that backs this rule, exactly, so the rule-reference verifier
(`scripts/verify-rule-refs.mjs` in the kit) can confirm it exists: a script path in
backticks, or `CI job "<exact name>"`. If nothing enforces it, write "Nothing yet: judgement".
Where a mechanical check is feasible, add it in the same change. Never claim a check that doesn't
exist.

## Actionable Triggers
List keywords, commands, or intents that should trigger this rule so the agent knows exactly when to apply it.
- Trigger 1: [e.g., "Searching for a string in a file"]
- Trigger 2: [e.g., "Executing a shell command on Windows"]

## Exceptions
When the rule doesn't apply, and who can grant an exception.
