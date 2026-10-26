import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import {readFile, stat} from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import {journalPathFor, repositoryRoot, shippedManifestPaths} from "./repository-files.js";
import {systemModelManifestFromFile} from "./system-model-manifest.js";

const sections = ["Steckbrief", "Herkunft", "Lizenz", "Dokumentation", "Vertrag", "Prüfung", "Grenzen", "Verlauf"];
const statuses = ["in Prüfung", "geprüft", "veröffentlicht", "zurückgezogen"];
const overviewPath = path.join(repositoryRoot, "docs", "index", "modellkatalog.md");

test("every shipped model has a complete journal entry naming its id and version", async () => {
  for (const manifestPath of await shippedManifestPaths()) {
    const journal = await journalOf(manifestPath);
    const manifest = await systemModelManifestFromFile(manifestPath);
    const label = path.relative(repositoryRoot, journalPathFor(manifestPath));
    assert.deepEqual(sections.filter((section) => !journal.includes(`\n## ${section}\n`)), [], label);
    assert.ok(statuses.some((status) => journal.includes(`**Status:** ${status}`)), `${label}: Status fehlt`);
    assert.ok(journal.includes(`\`${manifest.id}\``), `${label}: ID ${manifest.id}`);
    assert.ok(journal.includes(`\`${manifest.artifact.versionId}\``), `${label}: Version ${manifest.artifact.versionId}`);
  }
});

test("every journal records the checksum of a checked-in model file", async () => {
  for (const manifestPath of await shippedManifestPaths()) {
    const artifact = path.join(path.dirname(manifestPath), "model.onnx");
    if (!await exists(artifact)) continue;
    const checksum = createHash("sha256").update(await readFile(artifact)).digest("hex");
    assert.ok((await journalOf(manifestPath)).includes(checksum), `${path.relative(repositoryRoot, manifestPath)}: SHA-256 ${checksum}`);
  }
});

test("the catalog overview links every journal and every journal link resolves", async () => {
  const overview = await readFile(overviewPath, "utf8");
  for (const manifestPath of await shippedManifestPaths()) {
    const journalPath = journalPathFor(manifestPath);
    const link = path.relative(path.dirname(overviewPath), journalPath).split(path.sep).join("/");
    assert.ok(overview.includes(`](${link})`), `Übersicht verlinkt ${link} nicht`);
    for (const target of relativeLinks(await readFile(journalPath, "utf8"))) {
      assert.ok(await exists(path.resolve(path.dirname(journalPath), target)), `${path.relative(repositoryRoot, journalPath)}: ${target}`);
    }
  }
});

async function journalOf(manifestPath: string): Promise<string> {
  const journalPath = journalPathFor(manifestPath);
  assert.ok(await exists(journalPath), `Journal fehlt: ${path.relative(repositoryRoot, journalPath)}`);
  return readFile(journalPath, "utf8");
}

function relativeLinks(markdown: string): readonly string[] {
  return [...markdown.matchAll(/\]\(([^)#\s]+)\)/g)].map((match) => match[1] ?? "").filter((target) => !/^[a-z]+:/.test(target));
}

async function exists(filePath: string): Promise<boolean> {
  return stat(filePath).then(() => true, () => false);
}
