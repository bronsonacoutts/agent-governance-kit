#!/usr/bin/env node
// Closure-declaration parser: decides which work items a pull request closes.
// One parser for every caller: the CI guard, the pre-push hook and the post-merge job.
//
// usage: closure-keys.mjs --mode=guard|close --branch=<ref> --title=<t> < body.md
//   guard  exit 1 with a message per problem, exit 0 if the declaration is valid
//   close  print {"close":[...],"comment":[...]} and always exit 0
//
// Work-item keys look like <PREFIX>-<n>. Set WORK_ITEM_PREFIX (default "PROJ") for your tracker
// project, e.g. WORK_ITEM_PREFIX=ABC. Rules:
//   - every key in the branch name or title needs a body line starting "Closes <KEY>" or
//     "Part of <KEY>", never both. "Fixes"/"Resolves" are deliberately not accepted: one closing
//     verb keeps the contract unambiguous for people and for the post-merge job;
//   - only "Closes" lines close a work item on merge;
//   - any other hyphenated key in the body is an error: write it "<PREFIX> <n>" so the tracker's
//     integration doesn't act on a mention.
// Split each --name=value on the FIRST "=", so values (e.g. a PR title) may contain "=".
const args = Object.fromEntries(process.argv.slice(2).map(a => {
  const s = a.replace(/^--/, ""), i = s.indexOf("=");
  return i < 0 ? [s, ""] : [s.slice(0, i), s.slice(i + 1)];
}));
const body = await new Promise(r => { let s = ""; process.stdin.on("data", d => s += d).on("end", () => r(s)); });

const PREFIX = (process.env.WORK_ITEM_PREFIX || "PROJ").replace(/[^A-Za-z0-9]/g, "");
const KEY_SRC = `${PREFIX}-[1-9]\\d*`;
const KEY = new RegExp(`\\b${KEY_SRC}\\b`, "g");
const DECL = new RegExp(`^\\s*(Closes|Part of)\\s+(${KEY_SRC})\\b`, "i");

const primary = new Set([...(args.branch ?? "").matchAll(KEY), ...(args.title ?? "").matchAll(KEY)].map(m => m[0]));
const closes = new Set(), partOf = new Set();
for (const line of body.split(/\r?\n/)) {
  const m = line.match(DECL);
  if (m) (m[1].toLowerCase() === "part of" ? partOf : closes).add(m[2]);
}
const mentioned = new Set([...body.matchAll(KEY)].map(m => m[0]));

const errors = [];
for (const k of primary) {
  if (!closes.has(k) && !partOf.has(k)) errors.push(`${k} is in the branch or title but has no "Closes" or "Part of" line.`);
  if (closes.has(k) && partOf.has(k)) errors.push(`${k} is declared both "Closes" and "Part of". Pick one.`);
}
for (const k of mentioned) {
  if (!primary.has(k) && !closes.has(k) && !partOf.has(k))
    errors.push(`${k} is mentioned but not declared. Write it as "${k.replace("-", " ")}" so the tracker ignores it.`);
}

if (args.mode === "close") {
  console.log(JSON.stringify({ close: [...closes], comment: [...new Set([...primary, ...partOf])].filter(k => !closes.has(k)) }));
  process.exit(0);
}
if (errors.length) { errors.forEach(e => console.error(e)); process.exit(1); }
console.log("Closure declaration OK.");
