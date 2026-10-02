#!/usr/bin/env node
// Blocks file edits while the working copy is on a protected branch.
import { execSync } from "node:child_process";

const PROTECTED = new Set(["main", "master", "release"]);

const git = cmd => execSync(cmd, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
try {
  git("git rev-parse --git-dir");
} catch {
  process.exit(0); // not a git checkout: nothing to guard
}
// symbolic-ref also names the branch in a new repo with no commits yet, where rev-parse HEAD fails.
let branch = "";
try {
  branch = git("git symbolic-ref --short HEAD");
} catch {
  process.exit(0); // detached HEAD: not on any branch
}

if (PROTECTED.has(branch)) {
  console.error(
    `Blocked: this working copy is on "${branch}". Create a branch first:\n` +
    `  git switch -c <type>/<KEY>-<short-description>`
  );
  process.exit(2);
}
