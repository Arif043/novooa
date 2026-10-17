import assert from "node:assert/strict";
import test from "node:test";
import {
  executePromptNode,
  languageModelFor,
  type PromptNodeInput,
} from "./genkit-prompt-executor.js";

import {
  type GenkitLanguageModelResolver,
  type ResolvedGenkitLanguageModel,
} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {
  emptyLanguageModelDefaults,
  type LanguageModelDefaults,
} from "../../../../language_models/domain/entities/language-model-defaults.js";
import {type LanguageModelDefaultsStore} from "../../../../language_models/domain/repositories/language-model-defaults-store.js";
import {defaultGenerationOptions} from "../../../../language_models/domain/entities/generation-options.js";
import {ModelEmptyResponseError} from "../../../../language_models/infrastructure/errors/language-model-errors.js";
import {type PromptModelCall} from "./prompt-model-call.js";

test("returns only a data URL for an image prompt", async () => {
  const generatedImage = "data:image/png;base64,aW1hZ2U=";
  const calls: Array<{config?: unknown}> = [];

  const output = await executePromptNode(imageCall(fakeAi(generatedImage, calls)), imageInput());

  assert.equal(output.answer, generatedImage);
  assert.deepEqual(output.outputs, {
    dataUrl: {type: "string", value: generatedImage},
  });
  assert.deepEqual(calls[0]?.config, {responseModalities: ["IMAGE"]});
});

test("rejects an image response without a data URL", async () => {
  await assert.rejects(
    executePromptNode(imageCall(fakeAi("https://example.com/image.png", [])), imageInput()),
    ModelEmptyResponseError,
  );
});

// Deckt "Standardmodell verwenden" (leere languageModelId) ab: erst die in
// den Einstellungen gewählte Vorgabe versuchen, dann erst der bisherige
// Rückfall auf die äußere `ai`-Instanz (signalisiert durch `undefined`).
test("löst ein explizit gewähltes Sprachmodell direkt über den Resolver auf", async () => {
  const resolver = fakeResolver();

  const result = await languageModelFor("model-1", "team-1", resolver, undefined);

  assert.equal(result?.model, "model-1");
  assert.deepEqual(resolver.calls, [{teamId: "team-1", modelId: "model-1"}]);
});

test("wirft, wenn ein Sprachmodell explizit gewählt ist, aber kein Resolver konfiguriert ist", async () => {
  await assert.rejects(
    languageModelFor("model-1", "team-1", undefined, undefined),
    /nicht konfiguriert/,
  );
});

test("löst ohne explizite Wahl die konfigurierte Vorgabe auf", async () => {
  const resolver = fakeResolver();
  const defaultsStore = fakeDefaultsStore({blockModelId: "default-model", knowledgeAssistantModelId: null});

  const result = await languageModelFor(undefined, "team-1", resolver, defaultsStore);

  assert.equal(result?.model, "default-model");
  assert.deepEqual(resolver.calls, [{teamId: "team-1", modelId: "default-model"}]);
});

test("ohne gesetzte Vorgabe bleibt der bisherige Standardmodell-Pfad aktiv", async () => {
  const resolver = fakeResolver();
  const defaultsStore = fakeDefaultsStore(emptyLanguageModelDefaults);

  const result = await languageModelFor(undefined, "team-1", resolver, defaultsStore);

  assert.equal(result, undefined);
  assert.deepEqual(resolver.calls, []);
});

test("eine Vorgabe auf ein gelöschtes Modell fällt zurück, statt zu scheitern", async () => {
  const resolver = fakeResolver({throwsForModelId: "deleted-model"});
  const defaultsStore = fakeDefaultsStore({blockModelId: "deleted-model", knowledgeAssistantModelId: null});

  const result = await languageModelFor(undefined, "team-1", resolver, defaultsStore);

  assert.equal(result, undefined);
});

test("ohne Resolver oder Vorgabe-Speicher bleibt das Ergebnis undefined", async () => {
  const result = await languageModelFor(undefined, "team-1", undefined, undefined);

  assert.equal(result, undefined);
});

function fakeResolver(options: {throwsForModelId?: string} = {}) {
  const calls: Array<{teamId: string; modelId: string}> = [];
  return {
    calls,
    async resolve(teamId: string, modelId: string): Promise<ResolvedGenkitLanguageModel> {
      calls.push({teamId, modelId});
      if (modelId === options.throwsForModelId) {
        throw new Error("Das Sprachmodell wurde nicht gefunden.");
      }
      return {
        ai: {} as never,
        model: modelId as never,
        capabilities: {
          textGeneration: true,
          imageInput: false,
          structuredOutput: false,
          toolCalling: false,
          imageGeneration: false,
        },
        logContext: {},
        generationConfig: {configFor: () => ({})},
      };
    },
  } as GenkitLanguageModelResolver & {calls: Array<{teamId: string; modelId: string}>};
}

function fakeDefaultsStore(defaults: LanguageModelDefaults): LanguageModelDefaultsStore {
  return {
    async loadDefaults() {
      return defaults;
    },
    async saveDefaults() {},
  };
}

function imageInput(): PromptNodeInput {
  return {
    teamId: "team-1",
    generationOptions: defaultGenerationOptions,
    instruction: "Erstelle ein Logo.",
    context: "",
    outputType: "image",
    choices: [],
    structuredFields: [],
    mediaUrls: [],
  };
}

function fakeAi(
  imageUrl: string,
  calls: Array<{config?: unknown}>,
) {
  return {
    async generate(options: {config?: unknown}) {
      calls.push({config: options.config});
      return {media: {url: imageUrl}};
    },
  } as never;
}

function imageCall(ai: PromptModelCall["ai"]): PromptModelCall {
  return {ai, model: "image-model" as never, config: {}, logContext: {}, logger: silentLogger()};
}

function silentLogger(): PromptModelCall["logger"] {
  return {readableInfo() {}, readableError() {}, info() {}, error() {}, exception() {}};
}
