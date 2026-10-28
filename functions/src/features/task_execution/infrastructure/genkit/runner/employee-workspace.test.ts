import assert from "node:assert/strict";
import {access, mkdir, mkdtemp, readdir, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {genkit} from "genkit/beta";
import {runtimeTestDatabase} from "../../../../../db/runtime-database-test-support.js";
import {SQLiteEmployeeStore} from "../../../../employees/infrastructure/local/sqlite-employee-store.js";
import {DirectorySkillStore} from "../../../../skills/infrastructure/local/directory-skill-store.js";
import {type LlmOutputSpec} from "../../../../language_models/domain/prompting/llm-gateway.js";
import {defaultGenerationOptions} from "../../../../language_models/domain/entities/generation-options.js";
import {createLlmGateway} from "../../../../language_models/infrastructure/genkit/llm/llm-gateway-factory.js";
import {promptNodePrompt} from "../executors/prompt-node-prompt.js";
import {type ResolvedEmployee} from "./task-definition.js";
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

test("the employee runs with the constraint as system section, the employee's skills and the unchanged instruction", async (t) => {
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

  const response = await employeeTurn(ai, model, {
    employee: workspace!.employee!, instruction: "Fasse die Mail zusammen.", use: aiTurnMiddleware(workspace),
  });

  assert.equal(response.text, "fertig");
  const sent = requests[0];
  assert.match(sent.messages, /"role":"system".*<employee name=\\"Rezeption\\">\\nSei freundlich\.\\nAntworte kurz\.\\n<\/employee>/);
  assert.match(sent.messages, /Fasse die Mail zusammen\./);
  assert.ok(sent.tools.includes("use_skill"));
  assert.match(sent.messages, /pdf - Beschreibung von pdf/);
  assert.doesNotMatch(sent.messages, /mails - Beschreibung/, "only the employee's skills are offered");
});

test("an empty constraint adds no employee section", async () => {
  const ai = genkit({});
  let sent = "";
  const model = ai.defineModel({name: "fake-agent-model"}, async (request) => {
    sent = JSON.stringify(request.messages);
    return {message: {role: "model", content: [{text: "ok"}]}, finishReason: "stop"};
  });

  await employeeTurn(ai, model, {employee: {id: "e", name: "Leer", constraint: "  \n"}, instruction: "Hallo"});

  assert.doesNotMatch(sent, /<employee/);
});

test("an employee turn delivers structured output", async () => {
  const ai = genkit({});
  const model = ai.defineModel({name: "fake-agent-model", supports: {output: ["json"], constrained: "all"}}, async () => ({
    message: {role: "model", content: [{text: JSON.stringify({summe: 3})}]}, finishReason: "stop",
  }));

  const response = await employeeTurn(ai, model, {
    employee: {id: "e", name: "Buchhaltung", constraint: "Rechne genau."}, instruction: "1 + 2?",
    output: {kind: "structured", fields: [{name: "summe", description: "", type: "number"}]},
  });

  assert.deepEqual(response.data, {summe: 3});
});

test("an employee turn with an image keeps the constraint in the system part", async () => {
  const ai = genkit({});
  let sent = "";
  const model = ai.defineModel({name: "fake-agent-model", supports: {media: true}}, async (request) => {
    sent = JSON.stringify(request.messages);
    return {message: {role: "model", content: [{text: "ok"}]}, finishReason: "stop"};
  });

  await employeeTurn(ai, model, {
    employee: {id: "e", name: "Prüfung", constraint: "Prüfe Belege."}, instruction: "Was steht hier?",
    mediaUrls: ["data:image/png;base64,AAAA"],
  });

  assert.match(sent, /"role":"system".*Prüfe Belege\./);
  assert.match(sent, /Was steht hier\?/);
  assert.match(sent, /data:image\/png;base64,AAAA/);
});

test("the workspace of an employee exists as a directory that cleanup removes", async (t) => {
  const {employees, sources} = await setup(t);
  const employee = await employees.create("team-1", {name: "Rezeption", constraint: "", skills: ["pdf"]});

  const workspace = await prepareNodeAttachmentWorkspace(promptNode({employeeId: employee.id}), "team-1", sources);
  await access(workspace!.rootDirectory);
  await workspace!.cleanup();

  await assert.rejects(access(workspace!.rootDirectory));
});

/** Ein Turn eines Mitarbeiters über das LLM-Framework, wie ihn der Prompt-Baustein ausführt. */
function employeeTurn(ai: ReturnType<typeof genkit>, model: unknown, options: {
  employee: ResolvedEmployee; instruction: string; mediaUrls?: string[];
  use?: ReturnType<typeof aiTurnMiddleware>; output?: LlmOutputSpec;
}) {
  const prompt = promptNodePrompt({
    teamId: "team-1", instruction: options.instruction, outputType: "text", choices: [], structuredFields: [],
    mediaUrls: options.mediaUrls ?? [], generationOptions: defaultGenerationOptions, employee: options.employee,
  });
  const silent = {started: () => undefined, finished: () => undefined};
  return createLlmGateway(silent).generate({
    binding: {ai, model: model as never, config: {}, logContext: {}, use: options.use},
    prompt, label: "Test", output: options.output ?? {kind: "text"},
  });
}
