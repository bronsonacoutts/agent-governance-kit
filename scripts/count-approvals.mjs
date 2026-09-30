#!/usr/bin/env node
// Counts current approvals from people other than the author, for review-gate.sh's APPROVALS input.
//
// usage:
//   gh api --paginate repos/<owner>/<repo>/pulls/<n>/reviews \
//     | count-approvals.mjs --format=github --author=<login> --commit=<head sha>
//   curl .../pullRequests/<id>?api-version=7.1           | count-approvals.mjs --format=ado
//
// github: each reviewer's LATEST non-comment review counts, so a later "changes requested"
//         outranks an earlier approval. Bot reviews and the author's own review never count.
//         With --commit, an approval counts only if it was given on that commit, so new commits
//         pushed after an approval need a fresh one, whether or not the repo dismisses stale
//         reviews. Always pass the PR head SHA in CI.
//         Accepts one JSON array or several concatenated arrays (gh --paginate output).
// ado:    reviewers with vote 10 (approved) or 5 (approved with suggestions), excluding the PR
//         creator and group (container) reviewers. Azure Repos has no per-commit vote, so also turn
//         on the branch policy "Reset all approval votes when there are new changes".
const arg = n => (process.argv.find(a => a.startsWith(`--${n}=`)) ?? "").split("=").slice(1).join("=");
const format = arg("format") || "github";
const raw = await new Promise(r => { let s = ""; process.stdin.on("data", d => s += d).on("end", () => r(s)); });

function parseConcatenatedArrays(text) {
  const out = [];
  let depth = 0, start = -1, inStr = false, esc = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inStr) { if (esc) esc = false; else if (c === "\\") esc = true; else if (c === '"') inStr = false; continue; }
    if (c === '"') inStr = true;
    else if (c === "[") { if (depth++ === 0) start = i; }
    else if (c === "]" && --depth === 0) out.push(...JSON.parse(text.slice(start, i + 1)));
  }
  return out;
}

let count = 0;
if (format === "github") {
  const author = arg("author"), commit = arg("commit");
  const latest = new Map();
  for (const r of parseConcatenatedArrays(raw)) {
    if (!r?.user || r.user.type === "Bot" || r.user.login === author) continue;
    if (!["APPROVED", "CHANGES_REQUESTED", "DISMISSED"].includes(r.state)) continue;
    const prev = latest.get(r.user.login);
    if (!prev || new Date(r.submitted_at) >= new Date(prev.submitted_at)) latest.set(r.user.login, r);
  }
  count = [...latest.values()].filter(r => r.state === "APPROVED" && (!commit || r.commit_id === commit)).length;
} else if (format === "ado") {
  const pr = JSON.parse(raw);
  const creator = pr.createdBy?.id;
  count = (pr.reviewers ?? []).filter(r => r.id !== creator && !r.isContainer && (r.vote === 10 || r.vote === 5)).length;
} else {
  console.error(`Unknown --format "${format}". Use github or ado.`);
  process.exit(1);
}
console.log(count);
