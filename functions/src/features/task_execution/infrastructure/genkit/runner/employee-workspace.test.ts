import assert from "node:assert/strict";
import {access, mkdir, mkdtemp, readdir, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {genkit} from "genkit/beta";
import {runtimeTestDatabase} from "../../../../../db/runtime-database-test-support.js";
import {SQLiteEmployeeStore} from "../../../../employees/infrastructure/local/sqlite-employee-store.js";
import {DirectorySkillStore} from "../../../../skills/infrastructure/local/directory-skill-store.js";
import {runEmployeeAgentTurn} from "./employee-agent.js";
import {assertExclusiveDelegation} from "./employee-context.js";
import {aiTurnMiddleware} from "./node-attachment-genkit.js";
import {prepareNodeAttachmentWorkspace, type NodeAttachmentSources} from "./node-attachment-workspace.js";
import {type WorkflowNode} from "./task-definition.js";

const skillMd = (name: string) => `---\nname: ${name}\ndescription: Beschreibung von ${name}\n---\n# ${name}\nAnleitung für ${name}.\n`;

async function temporary(t: TestContext): Promise<string> {
  const directory = await mkdtemp(path.join(os.tmpdir(), "employee-workspace-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  return directory;
}

async function setup(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  const root = await temporary(t);
  for (const name of ["pdf", "mails", "eigener"]) {
    await mkdir(path.join(root, name), {recursive: true});
    await writeFile(path.join(root, name, "SKILL.md"), skillMd(name));
  }
  const employees = new SQLiteEmployeeStore(database);
  const sources: NodeAttachmentSources = {
    objectStore: {downloadToFile: async () => undefined},
    knowledgeBaseStore: {} as never,
    skillContentReader: new DirectorySkillStore(root),
    employeeStore: employees,
  };
  return {employees, sources};
}

function promptNode(config: Record<string, unknown> = {}): WorkflowNode {
  return {
    id: "node-1", title: "Prompt", description: "",
    config: {
      primitive: "prompt", instruction: "Fasse zusammen.", outputType: "text", choices: [], structuredFields: [],
      firstChoice: "", secondChoice: "", attachments: [], knowledgeAttachments: [], skillAttachments: [], ...config,
    },
  } as unknown as WorkflowNode;
}

test("the employee is loaded fresh and its skills are the only skills of the node", async (t) => {
  const {employees, sources} = await setup(t);
  const employee = await employees.create("team-1", {name: "Rezeption", constraint: "Sei freundlich.", skills: ["pdf", "mails"]});

  const workspace = await prepareNodeAttachmentWorkspace(promptNode({employeeId: employee.id}), "team-1", sources);
  t.after(() => workspace?.cleanup());

  assert.deepEqual(workspace?.employee, {id: employee.id, name: "Rezeption", constraint: "Sei freundlich."});
  assert.equal(workspace?.skillCount, 2);
  assert.deepEqual((await readdir(workspace.skillsDirectory!)).sort(), ["mails", "pdf"]);
});

test("changes to the employee apply to the next run without touching the node", async (t) => {
  const {employees, sources} = await setup(t);
  const employee = await employees.create("team-1", {name: "Rezeption", constraint: "Alt", skills: ["pdf"]});
  const node = promptNode({employeeId: employee.id});

  await employees.update("team-1", employee.id, {name: "Rezeption", constraint: "Neu", skills: ["mails"]});
  const workspace = await prepareNodeAttachmentWorkspace(node, "team-1", sources);
  t.after(() => workspace?.cleanup());

  assert.equal(workspace?.employee?.constraint, "Neu");
  assert.deepEqual(await readdir(workspace.skillsDirectory!), ["mails"]);
});

test("an employee without skills still produces a workspace carrying the constraint", async (t) => {
  const {employees, sources} = await setup(t);
  const employee = await employees.create("team-1", {name: "Nur Regeln", constraint: "Antworte auf Deutsch.", skills: []});

  const workspace = await prepareNodeAttachmentWorkspace(promptNode({employeeId: employee.id}), "team-1", sources);
  t.after(() => workspace?.cleanup());

  assert.equal(workspace?.employee?.constraint, "Antworte auf Deutsch.");
  assert.equal(workspace?.skillsDirectory, undefined);
  assert.equal(workspace?.skillCount, 0);
});

test("a node without employee keeps using its own skills", async (t) => {
  const {sources} = await setup(t);

  const workspace = await prepareNodeAttachmentWorkspace(promptNode({skillAttachments: [{name: "eigener", description: ""}]}), "team-1", sources);
  t.after(() => workspace?.cleanup());

  assert.equal(workspace?.employee, undefined);
  assert.deepEqual(await readdir(workspace!.skillsDirectory!), ["eigener"]);
  assert.equal(await prepareNodeAttachmentWorkspace(promptNode(), "team-1", sources), undefined, "nothing attached, no workspace");
});

test("an employee and own skills at the same time are rejected before anything is created", async (t) => {
  const {employees, sources} = await setup(t);
  const employee = await employees.create("team-1", {name: "Rezeption", constraint: "", skills: ["pdf"]});
  const node = promptNode({employeeId: employee.id, skillAttachments: [{name: "eigener", description: ""}]});
  const before = (await readdir(os.tmpdir())).filter((entry) => entry.startsWith("syscat-node-files-")).length;

  await assert.rejects(prepareNodeAttachmentWorkspace(node, "team-1", sources), /nicht zugleich einen Mitarbeiter und Fähigkeiten/);
  assert.throws(() => assertExclusiveDelegation(node), /Entferne eines von beiden/);

  assert.equal((await readdir(os.tmpdir())).filter((entry) => entry.startsWith("syscat-node-files-")).length, before);
  assert.doesNotThrow(() => assertExclusiveDelegation(promptNode({employeeId: employee.id})));
  assert.doesNotThrow(() => assertExclusiveDelegation(promptNode({skillAttachments: [{name: "x", description: ""}]})));
});

test("a deleted employee, another team's employee and a missing store fail readably", async (t) => {
  const {employees, sources} = await setup(t);
  const employee = await employees.create("team-1", {name: "Weg", constraint: "", skills: []});
  await employees.delete("team-1", employee.id);

  await assert.rejects(prepareNodeAttachmentWorkspace(promptNode({employeeId: employee.id}), "team-1", sources), /Mitarbeiter wurde nicht gefunden.*gelöscht/);
  await assert.rejects(prepareNodeAttachmentWorkspace(promptNode({employeeId: "gibt-es-nicht"}), "team-1", sources), /nicht gefunden/);
  await assert.rejects(prepareNodeAttachmentWorkspace(promptNode({employeeId: "x"}), "team-1", {...sources, employeeStore: undefined}), /in dieser Umgebung nicht verfügbar/);
});

test("a missing skill of the employee aborts with the skill message and leaves no temp folder behind", async (t) => {
  const {employees, sources} = await setup(t);
  const employee = await employees.create("team-1", {name: "Rezeption", constraint: "", skills: ["gibt-es-nicht"]});
  const count = async () => (await readdir(os.tmpdir())).filter((entry) => entry.startsWith("syscat-node-files-")).length;
  const before = await count();

  await assert.rejects(prepareNodeAttachmentWorkspace(promptNode({employeeId: employee.id}), "team-1", sources), /Skill „gibt-es-nicht“ wurde nicht gefunden/);

  assert.equal(await count(), before);
});

test("the agent runs with the constraint as system prompt, the employee's skills and the unchanged instruction", async (t) => {
  const {employees, sources} = await setup(t);
  const employee = await employees.create("team-1", {name: "Rezeption", constraint: "Sei freundlich.\nAntworte kurz.", skills: ["pdf"]});
  const workspace = await prepareNodeAttachmentWorkspace(promptNode({employeeId: employee.id}), "team-1", sources);
  t.after(() => workspace?.cleanup());
  const ai = genkit({});
  const requests: Array<{messages: string; tools: string[]}> = [];
  const model = ai.defineModel({name: "fake-agent-model"}, async (request) => {
    requests.push({messages: JSON.stringify(request.messages), tools: (request.tools ?? []).map((tool) => tool.name)});
    return {message: {role: "model", content: [{text: "fertig"}]}, finishReason: "stop"};
  });

  const response = await runEmployeeAgentTurn(ai, {
    employee: workspace!.employee!, model, prompt: "Fasse die Mail zusammen.", use: aiTurnMiddleware(workspace),
  });

  assert.equal(response.text, "fertig");
  const sent = requests[0];
  assert.match(sent.messages, /"role":"system".*Sei freundlich\.\\nAntworte kurz\./);
  assert.match(sent.messages, /Fasse die Mail zusammen\./);
  assert.ok(sent.tools.includes("use_skill"));
  assert.match(sent.messages, /pdf - Beschreibung von pdf/);
  assert.doesNotMatch(sent.messages, /mails - Beschreibung/, "only the employee's skills are offered");
});

test("an empty constraint sends no system prompt", async (t) => {
  const ai = genkit({});
  let sent = "";
  const model = ai.defineModel({name: "fake-agent-model"}, async (request) => {
    sent = JSON.stringify(request.messages);
    return {message: {role: "model", content: [{text: "ok"}]}, finishReason: "stop"};
  });

  await runEmployeeAgentTurn(ai, {employee: {id: "e", name: "Leer", constraint: "  \n"}, model, prompt: "Hallo"});

  assert.doesNotMatch(sent, /"role":"system"/);
});

test("agents live in a child registry: the runtime registry does not grow with every turn", async () => {
  const ai = genkit({});
  const model = ai.defineModel({name: "fake-agent-model"}, async () => ({message: {role: "model", content: [{text: "ok"}]}, finishReason: "stop"}));
  const count = async () => Object.keys(await ai.registry.listActions()).length;
  const before = await count();

  for (let turn = 0; turn < 5; turn++) {
    await runEmployeeAgentTurn(ai, {employee: {id: "e", name: "Rezeption", constraint: "Regel"}, model, prompt: "Hallo"});
  }

  assert.equal(await count(), before);
});

test("the workspace of an employee exists as a directory that cleanup removes", async (t) => {
  const {employees, sources} = await setup(t);
  const employee = await employees.create("team-1", {name: "Rezeption", constraint: "", skills: ["pdf"]});

  const workspace = await prepareNodeAttachmentWorkspace(promptNode({employeeId: employee.id}), "team-1", sources);
  await access(workspace!.rootDirectory);
  await workspace!.cleanup();

  await assert.rejects(access(workspace!.rootDirectory));
});
