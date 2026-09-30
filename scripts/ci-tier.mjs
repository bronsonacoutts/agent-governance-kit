#!/usr/bin/env node
// CI tier classifier. A tier label on a pull request is a request, never a grant: the diff decides.
//
// usage: ci-tier.mjs --requested=full|light|docs [--no-fail]   (changed files on stdin, one per line)
//   prints tier=<resolved tier>. Exits 1 when the request doesn't fit, naming the files, unless
//   --no-fail is given (use that where another job reports the error and you only need the tier).
//
// Env overrides (ERE, JavaScript syntax):
//   DOCS_PATHS         files a "docs" tier may contain
//   ALWAYS_FULL_PATHS  security-relevant and dependency files that always get the full suite
//   LIGHT_MAX_FILES    size cap for the "light" tier (default 25)
const requested = (process.argv.find(a => a.startsWith("--requested=")) ?? "=full").split("=")[1];
const files = (await new Promise(r => { let s = ""; process.stdin.on("data", d => s += d).on("end", () => r(s)); }))
  .split(/\r?\n/).map(f => f.trim()).filter(Boolean);

const DOCS = new RegExp(process.env.DOCS_PATHS || String.raw`\.(md|mdx|txt)$|^docs/|^sessions/`);
// CI definitions for every supported platform, the governance code and dependency manifests always
// get the full suite, so a change to CI control can never ride a lighter tier.
const ALWAYS_FULL = new RegExp(process.env.ALWAYS_FULL_PATHS ||
  String.raw`^(migrations/|src/auth/|src/billing/|\.github/|ci/|pipelines/|\.azure-pipelines/|azure-pipelines\.ya?ml$|\.gitlab-ci\.yml$|scripts/agent-governance/|hooks/|CODEOWNERS$)|(^|/)(package(-lock)?\.json|[\w.-]*\.lockb?)$`);
const LIGHT_MAX_FILES = Number(process.env.LIGHT_MAX_FILES || 25);

const TIERS = {
  full: () => [],
  light: () => {
    const m = files.filter(f => ALWAYS_FULL.test(f));
    if (files.length > LIGHT_MAX_FILES) m.push(`(${files.length} files, more than the ${LIGHT_MAX_FILES}-file limit)`);
    return m;
  },
  docs: () => files.filter(f => !DOCS.test(f) || ALWAYS_FULL.test(f)),
};

const noFail = process.argv.includes("--no-fail");
if (!TIERS[requested]) {
  console.error(`Unknown tier "${requested}". Use one of: ${Object.keys(TIERS).join(", ")}.`);
  console.log("tier=full");
  process.exit(noFail ? 0 : 1);
}

const misfits = TIERS[requested]();
if (misfits.length) {
  console.error(`Requested "${requested}", but these need the full suite:\n  ${misfits.join("\n  ")}`);
  console.log("tier=full");
  process.exit(noFail ? 0 : 1);
}
console.log(`tier=${requested}`);
