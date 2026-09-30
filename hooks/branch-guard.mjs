#!/usr/bin/env node
// Blocks file edits while the working copy is on a protected branch.
import { execSync } from "node:child_process";

const PROTECTED = new Set(["main", "master", "release"]);

let branch = "";
try {
  branch = execSync("git rev-parse --abbrev-ref HEAD", { encoding: "utf8" }).trim();
} catch {
  process.exit(0); // not a git checkout: nothing to guard
}

if (PROTECTED.has(branch)) {
  console.error(
    `Blocked: this working copy is on "${branch}". Create a branch first:\n` +
    `  git switch -c <type>/<KEY>-<short-description>`
  );
  process.exit(2);
}
