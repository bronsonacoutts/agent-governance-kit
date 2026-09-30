#!/usr/bin/env node
// Rule-reference verifier: fails when an agent rule names a script, package command or CI job that
// doesn't exist. A rule that describes a safeguard nobody built is worse than no rule, because
// agents trust it and skip the care the safeguard was meant to replace.
//
// Write rules so their claims are machine-readable:
//   - scripts and files in backticks:  `scripts/check-thing.mjs`
//   - package commands in backticks:   `npm run lint` (also `bun run`, `pnpm run`, `yarn run`)
//   - CI jobs or steps by exact name:  CI job "Access policy guard"
//
// Env overrides (comma-separated):
//   RULE_DOCS  files/dirs holding rules     (default: AGENTS.md,rules,.agents/rules; add your tools' own
//              instruction files, e.g. RULE_DOCS=AGENTS.md,.agents/rules,<tool>.md)
//   CI_DIRS    dirs holding CI definitions  (default: .github/workflows,ci/workflows,pipelines,.azure-pipelines)
//   PATH_ROOTS path prefixes treated as file references
//              (default: scripts,hooks,pre-push-checks,ci,.github,pipelines)
import { readFileSync, existsSync, readdirSync, lstatSync } from "node:fs";
import { join } from "node:path";

const list = (v, d) => (v || d).split(",").map(s => s.trim()).filter(Boolean);
// lstat, and skip symlinks: the rule and CI folders come from the pull request, so a link to an
// ancestor (endless recursion) or outside the checkout must never be followed.
const walk = p => {
  if (!existsSync(p)) return [];
  const st = lstatSync(p);
  if (st.isSymbolicLink()) return [];
  return st.isDirectory() ? readdirSync(p).flatMap(n => walk(join(p, n))) : [p];
};

const docs = list(process.env.RULE_DOCS, "AGENTS.md,rules,.agents/rules")
  .flatMap(walk).filter(f => f.endsWith(".md"));
const pkgScripts = existsSync("package.json")
  ? Object.keys(JSON.parse(readFileSync("package.json", "utf8")).scripts ?? {}) : [];
const ciText = list(process.env.CI_DIRS, ".github/workflows,ci/workflows,pipelines,.azure-pipelines")
  .flatMap(walk).filter(f => /\.ya?ml$/.test(f)).map(f => readFileSync(f, "utf8")).join("\n");
const roots = list(process.env.PATH_ROOTS, "scripts,hooks,pre-push-checks,ci,.github,pipelines")
  .map(r => r.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|");
const PATH_REF = new RegExp("`((?:" + roots + ")/[\\w./-]+\\.\\w+)`", "g");
const PKG_REF = /`(?:npm|bun|pnpm|yarn) run ([\w:.-]+)[^`]*`/g;
const JOB_REF = /CI (?:job|step) "([^"]+)"/g;
const jobDefined = name => new RegExp(`(?:^|\\n)\\s*-?\\s*(?:name|displayName|job|stage):\\s*['"]?${
  name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}['"]?\\s*(?:\\n|$)`).test(ciText);

const problems = [];
for (const file of docs) {
  const text = readFileSync(file, "utf8");
  for (const [, p] of text.matchAll(PATH_REF))
    if (!existsSync(p)) problems.push(`${file}: references missing file ${p}`);
  for (const [, name] of text.matchAll(PKG_REF))
    if (!pkgScripts.includes(name)) problems.push(`${file}: references missing package script "${name}"`);
  for (const [, job] of text.matchAll(JOB_REF))
    if (!jobDefined(job)) problems.push(`${file}: claims CI job "${job}", which no CI definition names`);
}

if (problems.length) { problems.forEach(p => console.error(p)); process.exit(1); }
console.log(`Rule references OK (${docs.length} rule files checked).`);
