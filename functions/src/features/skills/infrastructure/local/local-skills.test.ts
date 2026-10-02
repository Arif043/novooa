import assert from "node:assert/strict";
import {mkdir, mkdtemp, readFile, readdir, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {strToU8, zipSync} from "fflate";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {SkillAlreadyExistsError, SkillNotFoundError} from "../../domain/entities/stored-skill.js";
import {skillPackageFrom} from "../../domain/entities/skill-package.js";
import {DirectorySkillStore} from "./directory-skill-store.js";
import {InMemoryStagedSkillImports} from "./in-memory-staged-skill-imports.js";
import {skillRoutes} from "./local-skill-routes.js";
import {createSkillsModule, skillsDirectoryFor} from "./skills-composition.js";

const skillMd = (name: string, description = "Beschreibung") => `---\nname: ${name}\ndescription: ${description}\n---\n# ${name}\n`;

async function temporaryDirectory(t: TestContext): Promise<string> {
  const directory = await mkdtemp(path.join(os.tmpdir(), "skills-test-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  return directory;
}

async function writeSkill(root: string, folder: string, files: Record<string, string>): Promise<void> {
  for (const [relative, content] of Object.entries(files)) {
    await mkdir(path.dirname(path.join(root, folder, relative)), {recursive: true});
    await writeFile(path.join(root, folder, relative), content);
  }
}

test("the store lists hand-placed skill folders and reports problems as warnings", async (t) => {
  const root = await temporaryDirectory(t);
  await writeSkill(root, "pdf", {"SKILL.md": skillMd("pdf"), "references/r.md": "r", "scripts/run.py": "x"});
  await writeSkill(root, "ohne-beschreibung", {"SKILL.md": "---\nname: ohne-beschreibung\n---\nText"});
  await writeSkill(root, "anderer-name", {"SKILL.md": skillMd("etwas-anderes")});
  await writeSkill(root, "kein-skill", {"README.md": "x"});
  await writeSkill(root, ".versteckt", {"SKILL.md": skillMd("versteckt")});

  const skills = await new DirectorySkillStore(root).list();

  assert.deepEqual(skills.map((skill) => skill.name), ["anderer-name", "ohne-beschreibung", "pdf"]);
  assert.equal(skills.find((skill) => skill.name === "pdf")?.fileCount, 3);
  assert.match(skills[0].warnings[0], /weicht vom Ordnernamen ab/);
  assert.match(skills[1].warnings[0], /Beschreibung/);
  assert.deepEqual(skills[2].warnings, []);
});

test("listing a missing skills folder yields an empty list", async (t) => {
  const root = await temporaryDirectory(t);
  assert.deepEqual(await new DirectorySkillStore(path.join(root, "gibt-es-nicht")).list(), []);
});

test("saving writes the whole folder atomically and refuses duplicates", async (t) => {
  const root = await temporaryDirectory(t);
  const store = new DirectorySkillStore(path.join(root, "skills"));
  const skill = skillPackageFrom([
    {path: "SKILL.md", bytes: strToU8(skillMd("pdf"))}, {path: "scripts/run.py", bytes: strToU8("print()")},
  ], "pdf");

  const saved = await store.save(skill);

  assert.equal(saved.name, "pdf");
  assert.equal(await readFile(path.join(root, "skills", "pdf", "scripts", "run.py"), "utf8"), "print()");
  await assert.rejects(store.save(skill), SkillAlreadyExistsError);
  assert.deepEqual((await readdir(path.join(root, "skills"))).filter((entry) => entry.startsWith(".")), []);
});

test("deleting and copying reject missing skills and unsafe names", async (t) => {
  const root = await temporaryDirectory(t);
  const store = new DirectorySkillStore(root);
  await writeSkill(root, "pdf", {"SKILL.md": skillMd("pdf")});

  await assert.rejects(store.delete("gibt-es-nicht"), SkillNotFoundError);
  await assert.rejects(store.delete("../etc"), SkillNotFoundError);
  await assert.rejects(store.copyTo("../pdf", root), SkillNotFoundError);
  await store.delete("pdf");
  assert.deepEqual(await store.list(), []);
});

test("copying gives the middleware the folder name and a single-line description", async (t) => {
  const root = await temporaryDirectory(t);
  const workspace = await temporaryDirectory(t);
  await writeSkill(root, "pdf", {
    "SKILL.md": "---\nname: Anderer Name\ndescription: >\n  Erste Zeile\n  zweite Zeile.\nlicense: MIT\n---\n# Text\n",
    "references/r.md": "ref",
  });

  await new DirectorySkillStore(root).copyTo("pdf", path.join(workspace, "skills"));

  const markdown = await readFile(path.join(workspace, "skills", "pdf", "SKILL.md"), "utf8");
  assert.match(markdown, /^name: pdf$/m);
  assert.match(markdown, /^description: Erste Zeile zweite Zeile\.$/m);
  assert.match(markdown, /^license: MIT$/m);
  assert.ok(markdown.endsWith("# Text\n"));
  assert.equal(await readFile(path.join(workspace, "skills", "pdf", "references", "r.md"), "utf8"), "ref");
  assert.match(await readFile(path.join(root, "pdf", "SKILL.md"), "utf8"), /name: Anderer Name/, "the original stays untouched");
});

test("staged imports expire and are limited in number", () => {
  let now = 0;
  const staged = new InMemoryStagedSkillImports(1000, () => now);
  const entry = {origin: {kind: "folder" as const, reference: "x"}, packages: [], rejected: []};

  const id = staged.stage(entry);
  assert.equal(staged.find(id), entry);
  now = 1001;
  assert.equal(staged.find(id), undefined);

  now = 5000;
  const ids = Array.from({length: 11}, () => staged.stage(entry));
  assert.equal(staged.find(ids[0]), undefined);
  assert.equal(staged.find(ids[10]), entry);
  staged.discard(ids[10]);
  assert.equal(staged.find(ids[10]), undefined);
});

test("the skills folder defaults to the runtime root and can be overridden", () => {
  assert.equal(skillsDirectoryFor("/var/lib/novooa", {}), path.join("/var/lib/novooa", "skills"));
  assert.equal(skillsDirectoryFor("/var/lib/novooa", {NOVOOA_SKILLS_DIR: "/data/skills"}), "/data/skills");
  assert.equal(skillsDirectoryFor("/var/lib/novooa", {NOVOOA_SKILLS_DIR: "  "}), path.join("/var/lib/novooa", "skills"));
});

async function handler(t: TestContext) {
  const root = await temporaryDirectory(t);
  const published: string[] = [];
  const options = createSkillsModule(root, {publish: (topic) => published.push(topic)}, null).routes;
  return {root, published, options, routes: testingRoutes(skillRoutes, options)};
}

const zip = (files: Record<string, string>) => Buffer.from(zipSync(Object.fromEntries(Object.entries(files).map(([file, text]) => [file, strToU8(text)]))));
async function* chunks(buffer: Buffer) { yield buffer; }

test("a folder import is previewed, committed and shows up in the list", async (t) => {
  const {routes, published, root} = await handler(t);
  const file = (filePath: string, text: string) => ({path: filePath, contentBase64: Buffer.from(text).toString("base64")});

  const preview = await routes.handle({method: "POST", url: "/v1/skills/imports", body: {folder: {name: "skills", files: [
    file("a/SKILL.md", skillMd("a")), file("a/references/r.md", "r"), file("b/SKILL.md", skillMd("b")),
  ]}}});
  const body = preview?.body as {importId: string; candidates: Array<{name: string; fileCount: number}>};
  const commit = await routes.handle({method: "POST", url: `/v1/skills/imports/${body.importId}/commit`, body: {names: ["a"]}});
  const listed = await routes.handle({method: "GET", url: "/v1/skills", body: {}});

  assert.equal(preview?.statusCode, 201);
  assert.deepEqual(body.candidates.map((candidate) => [candidate.name, candidate.fileCount]), [["a", 2], ["b", 1]]);
  assert.equal(commit?.statusCode, 201);
  assert.deepEqual((listed?.body as {items: Array<{name: string}>}).items.map((skill) => skill.name), ["a"]);
  assert.equal(await readFile(path.join(root, "skills", "a", "references", "r.md"), "utf8"), "r");
  assert.deepEqual(published, ["skills"]);
});

test("committing renames a taken name and rejects expired or foreign selections", async (t) => {
  const {routes, root} = await handler(t);
  await writeSkill(path.join(root, "skills"), "a", {"SKILL.md": skillMd("a")});
  const preview = await routes.handleStream({method: "POST", url: "/v1/skills/imports/archive?name=a.zip",
    headers: {"content-type": "application/zip"}, body: chunks(zip({"a/SKILL.md": skillMd("a", "Neu")}))});
  const {importId, candidates} = preview?.body as {importId: string; candidates: Array<{nameTaken: boolean}>};

  const unknown = await routes.handle({method: "POST", url: `/v1/skills/imports/${importId}/commit`, body: {names: ["x"]}});
  const commit = await routes.handle({method: "POST", url: `/v1/skills/imports/${importId}/commit`, body: {names: ["a"]}});
  const expired = await routes.handle({method: "POST", url: `/v1/skills/imports/${importId}/commit`, body: {names: ["a"]}});

  assert.equal(candidates[0].nameTaken, true);
  assert.equal(unknown?.statusCode, 400);
  assert.deepEqual((commit?.body as {items: Array<{name: string}>}).items.map((skill) => skill.name), ["a-2"]);
  assert.match(await readFile(path.join(root, "skills", "a-2", "SKILL.md"), "utf8"), /^name: a-2$/m);
  assert.equal(expired?.statusCode, 400);
  assert.match((expired?.body as {error: string}).error, /abgelaufen/);
});

test("imports need exactly one source and a zip content type", async (t) => {
  const {routes} = await handler(t);

  const none = await routes.handle({method: "POST", url: "/v1/skills/imports", body: {}});
  const wrongType = await routes.handle({method: "POST", url: "/v1/skills/imports/archive", body: {}});
  const broken = await routes.handleStream({method: "POST", url: "/v1/skills/imports/archive",
    headers: {"content-type": "application/zip"}, body: chunks(Buffer.from("kein zip"))});

  assert.equal(none?.statusCode, 400);
  assert.equal(wrongType?.statusCode, 415);
  assert.equal(broken?.statusCode, 400);
  assert.match((broken?.body as {error: string}).error, /kein gültiges ZIP/);
});

test("skills are deleted by name and report the folder location", async (t) => {
  const {routes, root, published} = await handler(t);
  await writeSkill(path.join(root, "skills"), "pdf", {"SKILL.md": skillMd("pdf")});

  const location = await routes.handle({method: "GET", url: "/v1/skills/location", body: {}});
  const missing = await routes.handle({method: "DELETE", url: "/v1/skills/gibt-es-nicht", body: {}});
  const removed = await routes.handle({method: "DELETE", url: "/v1/skills/pdf", body: {}});
  const listed = await routes.handle({method: "GET", url: "/v1/skills", body: {}});

  assert.deepEqual(location?.body, {path: path.join(root, "skills")});
  assert.equal(missing?.statusCode, 404);
  assert.equal(removed?.statusCode, 200);
  assert.deepEqual((listed?.body as {items: unknown[]}).items, []);
  assert.deepEqual(published, ["skills"]);
});
