#!/usr/bin/env node
// Catalogue completeness check: fails when a file (or folder) in a catalogued location isn't named,
// in backticks, in its catalogue doc. Agents reuse what they can find; an uncatalogued component
// gets rebuilt in parallel by the next session.
//
// Config: catalogues.json at the repo root (or CATALOGUE_CONFIG=<path>), an array of
//   { "dir": "src/ui", "doc": "docs/component-catalogue.md", "ext": [".tsx"] }
//   { "dir": "server/functions", "doc": "docs/function-catalogue.md", "dirsAreItems": true }
// "dirsAreItems": each sub-folder is one item (folders starting with "_" are skipped as shared code).
// Files whose name starts with "_" or ends in .test.* / .spec.* are skipped.
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { basename, extname } from "node:path";

const configPath = process.env.CATALOGUE_CONFIG || "catalogues.json";
if (!existsSync(configPath)) {
  console.error(`No catalogue config at ${configPath}. Create it (see this script's header).`);
  process.exit(1);
}
const CATALOGUES = JSON.parse(readFileSync(configPath, "utf8"));

const problems = [];
for (const c of CATALOGUES) {
  if (!existsSync(c.dir)) { problems.push(`${configPath}: catalogued folder ${c.dir} doesn't exist`); continue; }
  if (!existsSync(c.doc)) { problems.push(`${configPath}: catalogue doc ${c.doc} doesn't exist`); continue; }
  const doc = readFileSync(c.doc, "utf8");
  const items = readdirSync(c.dir, { withFileTypes: true })
    .filter(e => !e.name.startsWith("_"))
    .filter(e => c.dirsAreItems
      ? e.isDirectory()
      : e.isFile() && (c.ext ?? []).includes(extname(e.name)) && !/\.(test|spec)\.\w+$/.test(e.name))
    .map(e => c.dirsAreItems ? e.name : basename(e.name, extname(e.name)));
  for (const item of items)
    if (!doc.includes("`" + item + "`")) problems.push(`${c.dir}/${item} is not listed in ${c.doc}`);
}

if (problems.length) {
  problems.forEach(m => console.error(m));
  console.error("Add an entry, or reuse an existing item from the catalogue.");
  process.exit(1);
}
console.log(`Catalogues complete (${CATALOGUES.length} checked).`);
