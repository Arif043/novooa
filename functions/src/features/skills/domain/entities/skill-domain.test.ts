import assert from "node:assert/strict";
import test from "node:test";
import {discoverSkills} from "./skill-discovery.js";
import {parseSkillManifest} from "./skill-manifest.js";
import {SkillName} from "./skill-name.js";
import {safeSkillPath, skillLimits, SkillPackageError, skillPackageFrom, type SkillFile} from "./skill-package.js";

const text = (path: string, content: string): SkillFile => ({path, bytes: new TextEncoder().encode(content)});
const skillMd = (fields: string) => `---\n${fields}\n---\n# Anleitung\n`;

test("SkillName accepts exactly the names of the agentskills.io standard", () => {
  for (const valid of ["pdf-processing", "a", "data-analysis-2", "x".repeat(64), "größe"]) {
    assert.notEqual(SkillName.parse(valid), null, valid);
  }
  for (const invalid of ["", "PDF-Processing", "-pdf", "pdf-", "pdf--processing", "pdf processing", "a_b", "x".repeat(65)]) {
    assert.equal(SkillName.parse(invalid), null, invalid);
  }
});

test("SkillName.slugFrom turns titles into valid names", () => {
  assert.equal(SkillName.slugFrom("Next.js Development")?.value, "next-js-development");
  assert.equal(SkillName.slugFrom("  Äpfel & Birnen!  ")?.value, "apfel-birnen");
  assert.equal(SkillName.slugFrom("!!!"), null);
  assert.equal(SkillName.slugFrom("a".repeat(80))?.value.length, 64);
});

test("SkillName.uniqueFor appends a counter and respects the length limit", () => {
  const base = SkillName.parse("review")!;
  assert.equal(SkillName.uniqueFor(base, new Set()).value, "review");
  assert.equal(SkillName.uniqueFor(base, new Set(["review", "review-2"])).value, "review-3");
  const long = SkillName.parse("a".repeat(64))!;
  const next = SkillName.uniqueFor(long, new Set([long.value])).value;
  assert.ok(next.length <= 64 && next.endsWith("-2"));
});

test("the manifest reads required, optional and nested metadata fields", () => {
  const manifest = parseSkillManifest(skillMd([
    "name: pdf-processing",
    "description: >",
    "  Extrahiert Text",
    "  aus PDFs.",
    "license: Apache-2.0",
    "allowed-tools: Bash(git:*) Read",
    "metadata:",
    "  author: example-org",
    "  version: 1.0",
  ].join("\n")));
  assert.equal(manifest.name, "pdf-processing");
  assert.equal(manifest.description, "Extrahiert Text aus PDFs.");
  assert.equal(manifest.license, "Apache-2.0");
  assert.equal(manifest.allowedTools, "Bash(git:*) Read");
  assert.deepEqual(manifest.metadata, {author: "example-org", version: "1"});
  assert.equal(manifest.body, "# Anleitung\n");
});

test("the manifest tolerates missing or broken frontmatter", () => {
  assert.deepEqual(parseSkillManifest("# nur Text"), {body: "# nur Text"});
  assert.equal(parseSkillManifest("---\nname: [kaputt\n---\nText").name, undefined);
  assert.equal(parseSkillManifest("---\r\nname: a\r\ndescription: b\r\n---\r\nText").description, "b");
});

test("a valid package keeps its files and declared name", () => {
  const skill = skillPackageFrom([
    text("SKILL.md", skillMd("name: pdf-processing\ndescription: Verarbeitet PDFs.")),
    text("references/REFERENCE.md", "Details"),
  ], "irgendein-ordner");
  assert.equal(skill.name, "pdf-processing");
  assert.equal(skill.description, "Verarbeitet PDFs.");
  assert.deepEqual(skill.files.map((file) => file.path).sort(), ["SKILL.md", "references/REFERENCE.md"]);
  assert.deepEqual(skill.warnings, []);
});

test("an invalid or missing name is corrected with a warning", () => {
  const invalid = skillPackageFrom([text("SKILL.md", skillMd("name: Next.js Development\ndescription: x"))], "ordner");
  const missing = skillPackageFrom([text("SKILL.md", skillMd("description: x"))], "Mein Ordner");
  assert.equal(invalid.name, "next-js-development");
  assert.match(invalid.warnings[0], /erfüllt den Standard nicht/);
  assert.equal(missing.name, "mein-ordner");
  assert.match(missing.warnings[0], /keinen Namen/);
});

test("a package without SKILL.md or description is rejected readably", () => {
  assert.throws(() => skillPackageFrom([text("README.md", "x")], "a"), /fehlt die Datei SKILL.md/);
  assert.throws(() => skillPackageFrom([text("SKILL.md", skillMd("name: a"))], "a"), (error: unknown) =>
    error instanceof SkillPackageError && /Beschreibung/.test(error.message));
});

test("a package enforces file count and size limits", () => {
  const entry = text("SKILL.md", skillMd("name: a\ndescription: x"));
  const many = Array.from({length: skillLimits.maximumFiles}, (_, index) => text(`f${index}.txt`, "x"));
  assert.throws(() => skillPackageFrom([entry, ...many], "a"), /zu viele Dateien/);
  const big: SkillFile = {path: "assets/big.bin", bytes: new Uint8Array(skillLimits.maximumTotalBytes + 1)};
  assert.throws(() => skillPackageFrom([entry, big], "a"), /zu groß/);
});

test("path traversal and absolute paths are rejected, junk files are dropped", () => {
  const entry = text("SKILL.md", skillMd("name: a\ndescription: x"));
  assert.throws(() => skillPackageFrom([entry, text("../evil.sh", "x")], "a"), /Ungültiger Dateipfad/);
  assert.throws(() => skillPackageFrom([entry, text("/etc/passwd", "x")], "a"), /Ungültiger Dateipfad/);
  assert.throws(() => skillPackageFrom([entry, text("C:\\x", "x")], "a"), /Ungültiger Dateipfad/);
  const skill = skillPackageFrom([entry, text(".git/config", "x"), text("__MACOSX/._a", "x"), text("scripts\\run.py", "x")], "a");
  assert.deepEqual(skill.files.map((file) => file.path).sort(), ["SKILL.md", "scripts/run.py"]);
  assert.equal(safeSkillPath("a/./b//c"), "a/b/c");
});

test("discovery finds several skills in a repository and splits their files", () => {
  const found = discoverSkills([
    text("README.md", "Repo"),
    text("skills/alpha/SKILL.md", skillMd("name: alpha\ndescription: A")),
    text("skills/alpha/references/r.md", "r"),
    text("skills/beta/SKILL.md", skillMd("description: B")),
    text("skills/beta/scripts/run.py", "print()"),
    text("skills/kaputt/SKILL.md", skillMd("name: kaputt")),
  ], "repo");
  assert.deepEqual(found.packages.map((skill) => skill.name), ["alpha", "beta"]);
  assert.deepEqual(found.packages[0].files.map((file) => file.path).sort(), ["SKILL.md", "references/r.md"]);
  assert.deepEqual(found.packages[1].files.map((file) => file.path).sort(), ["SKILL.md", "scripts/run.py"]);
  assert.equal(found.rejected.length, 1);
  assert.match(found.rejected[0].reason, /Beschreibung/);
});

test("discovery handles a skill at the root and nested skills", () => {
  const root = discoverSkills([
    text("SKILL.md", skillMd("description: Wurzel")),
    text("assets/logo.txt", "x"),
    text("inner/SKILL.md", skillMd("name: inner\ndescription: Innen")),
    text("inner/data.txt", "y"),
  ], "mein-repo");
  assert.deepEqual(root.packages.map((skill) => skill.name).sort(), ["inner", "mein-repo"]);
  const outer = root.packages.find((skill) => skill.name === "mein-repo")!;
  assert.deepEqual(outer.files.map((file) => file.path).sort(), ["SKILL.md", "assets/logo.txt"]);
});

test("discovery can be limited to a sub path", () => {
  const files = [
    text("a/SKILL.md", skillMd("name: a\ndescription: A")),
    text("b/SKILL.md", skillMd("name: b\ndescription: B")),
  ];
  assert.deepEqual(discoverSkills(files, "repo", "b").packages.map((skill) => skill.name), ["b"]);
  assert.deepEqual(discoverSkills(files, "repo", "gibt-es-nicht").packages, []);
});
