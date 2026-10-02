import assert from "node:assert/strict";
import test from "node:test";
import {strToU8, zipSync} from "fflate";
import {SkillImportError} from "../domain/entities/skill-import-error.js";
import {ZipSkillSource} from "./archive/zip-skill-source.js";
import {FolderSkillSource} from "./files/folder-skill-source.js";
import {parseGitHubReference, refCandidates} from "./github/github-reference.js";
import {GitHubSkillSource} from "./github/github-skill-source.js";

const skillMd = (name: string, description = "Beschreibung") => `---\nname: ${name}\ndescription: ${description}\n---\n# ${name}\n`;
const zip = (files: Record<string, string>) => zipSync(Object.fromEntries(Object.entries(files).map(([path, text]) => [path, strToU8(text)])));

test("GitHub references accept URLs, shorthands and tree/blob addresses", () => {
  assert.deepEqual(parseGitHubReference("https://github.com/vercel-labs/skills"), {owner: "vercel-labs", repository: "skills", rest: [], isFile: false});
  assert.deepEqual(parseGitHubReference("github.com/o/r.git"), {owner: "o", repository: "r", rest: [], isFile: false});
  assert.deepEqual(parseGitHubReference("o/r"), {owner: "o", repository: "r", rest: [], isFile: false});
  assert.deepEqual(parseGitHubReference("https://github.com/o/r/tree/main/skills/pdf"), {owner: "o", repository: "r", rest: ["main", "skills", "pdf"], isFile: false});
  assert.equal(parseGitHubReference("https://github.com/o/r/blob/main/skills/pdf/SKILL.md").isFile, true);
});

test("GitHub references reject other hosts and malformed input", () => {
  assert.throws(() => parseGitHubReference("https://gitlab.com/o/r"), /nur GitHub/i);
  assert.throws(() => parseGitHubReference("https://github.com/nur-ein-segment"), /ungültig/);
  assert.throws(() => parseGitHubReference("kein url"), SkillImportError);
  assert.throws(() => parseGitHubReference("https://github.com/o/../x"), SkillImportError);
});

test("branch candidates cover branches with slashes and file addresses", () => {
  const tree = parseGitHubReference("https://github.com/o/r/tree/feature/x/skills/pdf");
  assert.deepEqual(refCandidates(tree).map((candidate) => [candidate.ref, candidate.subPath]), [
    ["feature", "x/skills/pdf"], ["feature/x", "skills/pdf"], ["feature/x/skills", "pdf"],
  ]);
  const file = parseGitHubReference("https://github.com/o/r/blob/main/skills/pdf/SKILL.md");
  assert.deepEqual(refCandidates(file)[0], {ref: "main", subPath: "skills/pdf"});
  assert.deepEqual(refCandidates(parseGitHubReference("o/r")), [{ref: "HEAD", subPath: ""}]);
});

test("the GitHub source downloads the repository zip and finds all skills", async () => {
  const requested: string[] = [];
  const source = new GitHubSkillSource((async (url: string) => {
    requested.push(url);
    return new Response(zip({
      "repo-abc/README.md": "x",
      "repo-abc/skills/alpha/SKILL.md": skillMd("alpha"),
      "repo-abc/skills/alpha/references/r.md": "r",
      "repo-abc/skills/beta/SKILL.md": skillMd("beta"),
    }));
  }) as unknown as typeof fetch);

  const found = await source.resolve({url: "https://github.com/o/repo"});

  assert.deepEqual(requested, ["https://codeload.github.com/o/repo/zip/HEAD"]);
  assert.deepEqual(found.packages.map((skill) => skill.name), ["alpha", "beta"]);
  assert.deepEqual(found.packages[0].files.map((file) => file.path).sort(), ["SKILL.md", "references/r.md"]);
});

test("the GitHub source limits the search to a sub path and retries branches with slashes", async () => {
  const requested: string[] = [];
  const source = new GitHubSkillSource((async (url: string) => {
    requested.push(url);
    if (url.endsWith("/zip/feature")) return new Response("nicht da", {status: 404});
    return new Response(zip({
      "r-feature-x/a/SKILL.md": skillMd("a"),
      "r-feature-x/b/SKILL.md": skillMd("b"),
    }));
  }) as unknown as typeof fetch);

  const found = await source.resolve({url: "https://github.com/o/r/tree/feature/x/b"});

  assert.deepEqual(requested, ["https://codeload.github.com/o/r/zip/feature", "https://codeload.github.com/o/r/zip/feature/x"]);
  assert.deepEqual(found.packages.map((skill) => skill.name), ["b"]);
});

test("the GitHub source explains missing repositories, rate limits and oversized downloads", async () => {
  const respond = (response: () => Response) => new GitHubSkillSource((async () => response()) as unknown as typeof fetch);

  await assert.rejects(respond(() => new Response("", {status: 404})).resolve({url: "o/r"}), /nicht gefunden.*privat/i);
  await assert.rejects(respond(() => new Response("", {status: 429})).resolve({url: "o/r"}), /begrenzt/);
  await assert.rejects(respond(() => new Response("x", {headers: {"content-length": String(26 * 1024 * 1024)}})).resolve({url: "o/r"}), /zu groß/);
  await assert.rejects(respond(() => new Response(zip({"r/README.md": "x"}))).resolve({url: "o/r"}), /kein Skill gefunden/);
  await assert.rejects(new GitHubSkillSource((async () => { throw new Error("offline"); }) as unknown as typeof fetch).resolve({url: "o/r"}), /nicht erreichbar/);
});

test("the ZIP source strips a common root folder and names a root skill after it", async () => {
  const found = await new ZipSkillSource().resolve({
    bytes: zip({"mein-skill/SKILL.md": skillMd("mein-skill"), "mein-skill/scripts/run.py": "print()"}),
    fileName: "download.zip",
  });

  assert.deepEqual(found.packages.map((skill) => skill.name), ["mein-skill"]);
  assert.deepEqual(found.packages[0].files.map((file) => file.path).sort(), ["SKILL.md", "scripts/run.py"]);
});

test("the ZIP source uses the file name for a skill at the archive root", async () => {
  const found = await new ZipSkillSource().resolve({
    bytes: zip({"SKILL.md": `---\ndescription: ohne Namen\n---\nText`, "assets/a.txt": "a"}),
    fileName: "Mein Skill.zip",
  });

  assert.equal(found.packages[0].name, "mein-skill");
  assert.match(found.packages[0].warnings[0], /keinen Namen/);
});

test("the ZIP source rejects invalid archives, empty archives and zip-slip entries", async () => {
  const source = new ZipSkillSource();

  await assert.rejects(source.resolve({bytes: strToU8("kein zip"), fileName: "a.zip"}), /kein gültiges ZIP/);
  await assert.rejects(source.resolve({bytes: zip({"x/readme.md": "a"}), fileName: "a.zip"}), /kein Skill gefunden/);
  const slip = await source.resolve({bytes: zip({"../evil/SKILL.md": skillMd("evil"), "gut/SKILL.md": skillMd("gut")}), fileName: "a.zip"});
  assert.deepEqual(slip.packages.map((skill) => skill.name), ["gut"]);
});

test("the folder source decodes base64 files and finds several skills", async () => {
  const file = (path: string, text: string) => ({path, contentBase64: Buffer.from(text).toString("base64")});
  const found = await new FolderSkillSource().resolve({name: "skills", files: [
    file("a/SKILL.md", skillMd("a")), file("a/references/r.md", "ä"), file("b/SKILL.md", skillMd("b")),
  ]});

  assert.deepEqual(found.packages.map((skill) => skill.name), ["a", "b"]);
  assert.equal(Buffer.from(found.packages[0].files.find((candidate) => candidate.path === "references/r.md")!.bytes).toString(), "ä");
  await assert.rejects(new FolderSkillSource().resolve({name: "leer", files: [file("x.txt", "a")]}), /kein Skill gefunden/);
});
