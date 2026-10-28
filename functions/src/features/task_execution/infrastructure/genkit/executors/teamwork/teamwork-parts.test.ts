import assert from "node:assert/strict";
import {mkdir, mkdtemp, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {nodeConfigSchema} from "../../runner/task-definition.js";
import {persistedResultFile, resultFilePath} from "./teamwork-file-outputs.js";
import {uniqueToolNames} from "./teamwork-member-runs.js";
import {memberTaskPrompt} from "./teamwork-prompts.js";

const member = (employeeId: string, responsibility = "Recherche") => ({employeeId, responsibility});

test("the configuration needs a responsibility per member, unique members, at most five and a review setting", () => {
  const parse = (config: Record<string, unknown>) =>
    nodeConfigSchema.safeParse({primitive: "teamwork", review: {enabled: true}, ...config});

  assert.ok(parse({members: [member("a"), member("b")], outputFields: [{name: "x", type: "file", fileFormat: "csv"}]}).success);
  assert.equal(parse({members: [member("a", "  ")]}).success, false);
  assert.equal(parse({members: [member("a"), member("a")]}).success, false);
  assert.equal(parse({members: ["a", "b", "c", "d", "e", "f"].map((id) => member(id))}).success, false);
  assert.equal(parse({members: [member("a")], review: undefined}).success, false);
  assert.equal(nodeConfigSchema.safeParse({primitive: "prompt", structuredFields: [{name: "x", type: "file"}]}).success, false,
    "files are a teamwork-only field type");
});

test("tool names are ASCII and unique", () => {
  assert.deepEqual(uniqueToolNames(["Recherche", "Jürgen Müller", "recherche", "???"]), [
    "delegate_to_recherche", "delegate_to_jurgen_muller", "delegate_to_recherche_2", "delegate_to_member_4",
  ]);
});

test("a task is split into what to do, the expected result and the boundaries", () => {
  const prompt = memberTaskPrompt({task: "Finde X.", expectedResult: "Eine Zahl.", boundaries: "Nicht Y."});

  assert.equal(prompt, [
    "<task>\nFinde X.\n</task>",
    "<context name=\"expected_result\">\nEine Zahl.\n</context>",
    "<context name=\"boundaries\">\nNicht Y.\n</context>",
  ].join("\n\n"));
  assert.doesNotMatch(memberTaskPrompt({task: "A", expectedResult: "B", boundaries: " "}), /boundaries/);
});

async function shared(t: TestContext) {
  const root = await mkdtemp(path.join(os.tmpdir(), "teamwork-files-"));
  t.after(() => rm(root, {recursive: true, force: true}));
  const sharedDirectory = path.join(root, "shared");
  await mkdir(sharedDirectory);
  await writeFile(path.join(root, "1-anhang.txt"), "Anhang");
  return sharedDirectory;
}

test("only files below shared/ are results", async (t) => {
  const sharedDirectory = await shared(t);

  assert.equal(resultFilePath("bericht", "shared/a/b.md", sharedDirectory), path.join(sharedDirectory, "a/b.md"));
  for (const reported of ["1-anhang.txt", "shared/../1-anhang.txt", "/etc/passwd", "", 42]) {
    assert.throws(() => resultFilePath("bericht", reported, sharedDirectory), /Für das Feld „bericht“ fehlt eine Ergebnisdatei unter shared\//);
  }
});

test("a result file becomes a new team file with the content type of its format", async (t) => {
  const sharedDirectory = await shared(t);
  await writeFile(path.join(sharedDirectory, "liste.csv"), "a;b\n1;2");
  const written: Array<Record<string, unknown>> = [];
  const teamFileStore = {
    writeTeamFile: async (input: Record<string, unknown>) => {
      written.push(input);
      return {fileId: "f1", versionId: "v1", storagePath: "p", displayName: String(input.fileName),
        contentType: String(input.contentType), sizeBytes: 7, folderId: null, ownerUid: "u", isNewFile: true};
    },
  } as never;
  const field = {name: "liste", description: "", type: "file" as const, fileFormat: "csv" as const};

  const value = await persistedResultFile(field, "shared/liste.csv", {teamId: "t", sharedDirectory, teamFileStore});

  assert.equal(value.type, "file");
  assert.deepEqual(written[0], {teamId: "t", content: "a;b\n1;2", fileName: "liste.csv", contentType: "text/csv", folderId: null, targetFileId: null});
  await assert.rejects(persistedResultFile(field, "shared/fehlt.csv", {teamId: "t", sharedDirectory, teamFileStore}), /wurde nicht geschrieben/);
});
