import {mkdir, mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {type TestContext} from "node:test";
import {genkit, type GenkitBeta} from "genkit/beta";
import {type ModelArgument} from "genkit";
import {type TeamworkExecutionRequest} from "../../../../domain/entities/teamwork-execution.js";
import {defaultLanguageModelCapabilities, type LanguageModelCapabilities} from "../../../../../language_models/domain/entities/language-model.js";
import {defaultGenerationOptions} from "../../../../../language_models/domain/entities/generation-options.js";
import {type GenkitLanguageModelResolver} from "../../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";

/** Test-Hilfen der Teamarbeit: Fake-Modelle je eigener Genkit-Instanz, Arbeitsordner, Anfrage, Protokoll. */
export type FakeModel = {ai: GenkitBeta; model: ModelArgument; requests: Array<{messages: string; tools: string[]}>};
type Reply = (call: number, request: {messages: unknown[]}) => Record<string, unknown>;

export function fakeModel(name: string, reply: Reply): FakeModel {
  const ai = genkit({});
  const requests: FakeModel["requests"] = [];
  const model = ai.defineModel({name}, async (request) => {
    requests.push({messages: JSON.stringify(request.messages), tools: (request.tools ?? []).map((tool) => tool.name)});
    return {message: {role: "model", content: [reply(requests.length, request)]}, finishReason: "stop"};
  });
  return {ai, model, requests};
}

export function resolverFor(
  models: Record<string, FakeModel>, capabilities: Partial<LanguageModelCapabilities> = {toolCalling: true},
  capabilitiesById: Record<string, Partial<LanguageModelCapabilities>> = {},
): GenkitLanguageModelResolver {
  return {
    resolve: async (_teamId, id) => ({
      ai: models[id].ai, model: models[id].model, logContext: {model: id},
      capabilities: {...defaultLanguageModelCapabilities, ...capabilities, ...capabilitiesById[id]},
      generationConfig: {configFor: () => ({})},
    }),
  };
}

export async function workspaceFor(t: TestContext) {
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

export const request: TeamworkExecutionRequest = {
  teamId: "team-1", instruction: "Wie groß ist X?", languageModelId: "orchestrator",
  generationOptions: defaultGenerationOptions, mediaUrls: [], review: {enabled: false},
  outputFields: [
    {name: "antwort", description: "", type: "string"},
    {name: "groesse", description: "", type: "number"},
  ],
};

export function delegation(ref: string, task: string) {
  return {toolRequest: {name: "delegate_to_recherche", ref, input: {task, expectedResult: "Eine Zahl."}}};
}

export const result = (antwort: string, groesse: number) => ({text: JSON.stringify({antwort, groesse})});

export const logger = () => {
  const lines: string[] = [];
  return {lines, info() {}, error() {}, exception() {}, readableInfo: (line: string) => lines.push(line), readableError: (line: string) => lines.push(line)};
};
