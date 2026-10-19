import assert from "node:assert/strict";
import {access, mkdir, mkdtemp, readdir, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../../db/runtime-database-test-support.js";
import {SQLiteEmployeeStore} from "../../../../employees/infrastructure/local/sqlite-employee-store.js";
import {DirectorySkillStore} from "../../../../skills/infrastructure/local/directory-skill-store.js";
import {prepareNodeAttachmentWorkspace} from "./node-attachment-workspace.js";
import {type WorkflowNode} from "./task-definition.js";

async function setup(t: TestContext) {
  const skillsRoot = await mkdtemp(path.join(os.tmpdir(), "teamwork-skills-"));
  t.after(() => rm(skillsRoot, {recursive: true, force: true}));
  for (const name of ["pdf", "mails"]) {
    await mkdir(path.join(skillsRoot, name));
    await writeFile(path.join(skillsRoot, name, "SKILL.md"), `---\nname: ${name}\ndescription: ${name}\n---\n`);
  }
  const employees = new SQLiteEmployeeStore(await runtimeTestDatabase(t));
  const sources = {
    objectStore: {downloadToFile: async (_path: string, destination: string) => writeFile(destination, "inhalt")},
    knowledgeBaseStore: {} as never,
    skillContentReader: new DirectorySkillStore(skillsRoot),
    employeeStore: employees,
  };
  return {employees, sources};
}

function teamworkNode(members: Array<{employeeId: string; responsibility: string}>): WorkflowNode {
  return {
    id: "t", primitive: "teamwork", title: "Team", description: "",
    config: {
      primitive: "teamwork", instruction: "Los", members, outputFields: [], knowledgeAttachments: [],
      attachments: [{id: "a", storagePath: "s", generation: "1", displayName: "Vertrag.pdf", contentType: "application/pdf", sizeBytes: 6}],
    },
  } as unknown as WorkflowNode;
}

test("each member gets only its own skills; attachments and the shared folder are common", async (t) => {
  const {employees, sources} = await setup(t);
  const research = await employees.create("team-1", {name: "Recherche", constraint: "Gründlich", skills: ["pdf"]});
  const office = await employees.create("team-1", {name: "Büro", constraint: "", skills: ["mails"]});

  const workspace = (await prepareNodeAttachmentWorkspace(teamworkNode([
    {employeeId: research.id, responsibility: " Fakten finden "},
    {employeeId: office.id, responsibility: "Mails schreiben"},
  ]), "team-1", sources))!;
  t.after(() => workspace.cleanup());

  const [first, second] = workspace.team!.members;
  assert.deepEqual(first.employee, {id: research.id, name: "Recherche", constraint: "Gründlich"});
  assert.equal(first.responsibility, "Fakten finden");
  assert.deepEqual(await readdir(first.skillsDirectory!), ["pdf"]);
  assert.deepEqual(await readdir(second.skillsDirectory!), ["mails"]);
  assert.equal(workspace.team!.sharedDirectory, path.join(workspace.rootDirectory, "shared"));
  assert.match(workspace.files[0].filename, /Vertrag\.pdf$/);
  await access(path.join(workspace.rootDirectory, workspace.files[0].filename));
  assert.match(path.basename(workspace.rootDirectory), /^novooa-teamwork-/);
});

test("a deleted member stops the run before a folder is created", async (t) => {
  const {sources} = await setup(t);

  await assert.rejects(
    prepareNodeAttachmentWorkspace(teamworkNode([{employeeId: "weg", responsibility: "x"}]), "team-1", sources),
    /Mitarbeiter wurde nicht gefunden/,
  );
});
