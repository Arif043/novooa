import assert from "node:assert/strict";
import {mkdir, mkdtemp, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {genkit, type GenkitBeta} from "genkit/beta";
import {GenkitError, type ModelArgument} from "genkit";
import {defaultLanguageModelCapabilities} from "../../../../../language_models/domain/entities/language-model.js";
import {defaultGenerationOptions} from "../../../../../language_models/domain/entities/generation-options.js";
import {type GenkitLanguageModelResolver} from "../../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {GenkitTeamworkExecutor} from "./genkit-teamwork-executor.js";

type FakeModel = {ai: GenkitBeta; model: ModelArgument; requests: Array<{messages: string; tools: string[]}>};
type Reply = (call: number, request: {messages: unknown[]}) => Record<string, unknown>;

function fakeModel(name: string, reply: Reply): FakeModel {
  const ai = genkit({});
  const requests: FakeModel["requests"] = [];
  const model = ai.defineModel({name}, async (request) => {
    requests.push({messages: JSON.stringify(request.messages), tools: (request.tools ?? []).map((tool) => tool.name)});
    return {message: {role: "model", content: [reply(requests.length, request)]}, finishReason: "stop"};
  });
  return {ai, model, requests};
}

function resolverFor(models: Record<string, FakeModel>, capabilities = {toolCalling: true}): GenkitLanguageModelResolver {
  return {
    resolve: async (_teamId, id) => ({
      ai: models[id].ai, model: models[id].model, logContext: {model: id},
      capabilities: {...defaultLanguageModelCapabilities, ...capabilities},
      generationConfig: {configFor: () => ({})},
    }),
  };
}

async function workspaceFor(t: TestContext) {
  const rootDirectory = await mkdtemp(path.join(os.tmpdir(), "teamwork-test-"));
  t.after(() => rm(rootDirectory, {recursive: true, force: true}));
  const sharedDirectory = path.join(rootDirectory, "shared");
  await mkdir(sharedDirectory);
  return {
    rootDirectory, files: [], knowledgeFiles: [], skillCount: 0, cleanup: async () => undefined,
    team: {sharedDirectory, members: [{
      employee: {id: "e1", name: "Recherche", constraint: "Du recherchierst gründlich."},
      responsibility: "Findet Fakten", languageModelId: "worker",
    }]},
  };
}

const request = {
  teamId: "team-1", instruction: "Wie groß ist X?", languageModelId: "orchestrator",
  generationOptions: defaultGenerationOptions, mediaUrls: [],
  outputFields: [
    {name: "antwort", description: "", type: "string" as const},
    {name: "groesse", description: "", type: "number" as const},
  ],
};

const logger = () => {
  const lines: string[] = [];
  return {lines, info() {}, error() {}, exception() {}, readableInfo: (line: string) => lines.push(line), readableError: (line: string) => lines.push(line)};
};

test("the orchestrator delegates to a member on its own model and returns the structured result", async (t) => {
  const orchestrator = fakeModel("orchestrator", (call) => call === 1
    ? {toolRequest: {name: "delegate_to_recherche", ref: "1", input: {task: "Finde die Größe von X."}}}
    : {text: JSON.stringify({antwort: "X ist 42 groß", groesse: 42})});
  const worker = fakeModel("worker", () => ({text: "X ist 42."}));
  const log = logger();
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace: await workspaceFor(t), logger: log,
    languageModelResolver: resolverFor({orchestrator, worker}),
  });

  const result = (await executor.execute(request))._unsafeUnwrap();

  assert.deepEqual(result.fields, {antwort: "X ist 42 groß", groesse: 42});
  assert.ok(orchestrator.requests[0].tools.includes("delegate_to_recherche"));
  assert.match(orchestrator.requests[0].messages, /Findet Fakten/);
  assert.match(worker.requests[0].messages, /"role":"system".*Du recherchierst gründlich/);
  assert.match(worker.requests[0].messages, /Finde die Größe von X\..*shared\//);
  assert.ok(worker.requests[0].tools.includes("write_file"), "members may write to the shared folder");
  assert.match(orchestrator.requests[1].messages, /X ist 42\./);
  assert.ok(log.lines.some((line) => line.startsWith("[Teamwork] Task for Recherche\nFinde die Größe von X.")));
  assert.ok(log.lines.some((line) => line.startsWith("[Teamwork] Answer from Recherche (")));
});

test("a failing member is reported to the orchestrator, which keeps working", async (t) => {
  const orchestrator = fakeModel("orchestrator", (call) => call === 1
    ? {toolRequest: {name: "delegate_to_recherche", ref: "1", input: {task: "Hilf."}}}
    : {text: JSON.stringify({antwort: "ohne Hilfe", groesse: 0})});
  const worker = fakeModel("worker", () => {
    throw new GenkitError({status: "INVALID_ARGUMENT", message: "Modell lehnt ab"});
  });
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace: await workspaceFor(t), logger: logger(),
    languageModelResolver: resolverFor({orchestrator, worker}),
  });

  const result = (await executor.execute(request))._unsafeUnwrap();

  assert.equal(result.fields.antwort, "ohne Hilfe");
  assert.match(orchestrator.requests[1].messages, /Der Auftrag an Recherche ist gescheitert/);
});

test("an orchestrator model without tool calls fails readably before anything runs", async (t) => {
  const orchestrator = fakeModel("orchestrator", () => ({text: "{}"}));
  const worker = fakeModel("worker", () => ({text: ""}));
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace: await workspaceFor(t), logger: logger(),
    languageModelResolver: resolverFor({orchestrator, worker}, {toolCalling: false}),
  });

  const failure = (await executor.execute(request))._unsafeUnwrapErr();

  assert.match(failure.message, /Orchestrator unterstützt keine Werkzeugaufrufe/);
  assert.equal(orchestrator.requests.length, 0);
});

test("result files written to the shared folder are reported by path", async (t) => {
  const workspace = await workspaceFor(t);
  await writeFile(path.join(workspace.team.sharedDirectory, "bericht.md"), "# Bericht");
  const orchestrator = fakeModel("orchestrator", () => ({text: JSON.stringify({bericht: "shared/bericht.md"})}));
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace, logger: logger(),
    languageModelResolver: resolverFor({orchestrator, worker: fakeModel("worker", () => ({text: ""}))}),
  });

  const result = (await executor.execute({
    ...request, outputFields: [{name: "bericht", description: "", type: "file", fileFormat: "markdown"}],
  }))._unsafeUnwrap();

  assert.deepEqual(result.fields, {bericht: "shared/bericht.md"});
  assert.match(orchestrator.requests[0].messages, /bericht: Markdown/);
});
