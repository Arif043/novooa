import assert from "node:assert/strict";
import test from "node:test";
import {GenkitError} from "genkit";
import {GenkitPromptExecutor, type PromptNodeInput} from "./genkit-prompt-executor.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {ollamaGenerationConfig} from "../../../../language_models/infrastructure/genkit/generation-config/ollama-generation-config.js";
import {defaultGenerationOptions, generationOptionsFrom} from "../../../../language_models/domain/entities/generation-options.js";
import {type GenkitLanguageModelResolver} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";

test("the port returns a failure with a stable code instead of throwing", async () => {
  const schemaViolation = new GenkitError({status: "INVALID_ARGUMENT", message: "Schema validation failed. null"});
  const executor = new GenkitPromptExecutor({
    ai: {async generate() { throw schemaViolation; }} as never,
    logger: silentLogger(),
  });

  const answerOrFailure = await executor.execute({...imageInput(), outputType: "structured", structuredFields: [
    {name: "Datum", description: "", type: "string"},
  ]});

  assert.ok(answerOrFailure.isErr());
  assert.equal(answerOrFailure.error.code, "outputSchemaViolated");
});

test("passes the provider config translated from the generation options", async () => {
  const configs: unknown[] = [];
  const executor = new GenkitPromptExecutor({
    ai: {} as never,
    languageModelResolver: {async resolve() {
      return {
        ai: {async generate(input: {config?: unknown}) { configs.push(input.config); return {text: "ok"}; }} as never,
        model: "ollama/qwen3-vl:8b" as never,
        capabilities: {textGeneration: true, imageInput: true, structuredOutput: true, toolCalling: false, imageGeneration: false},
        logContext: {},
        generationConfig: ollamaGenerationConfig,
      };
    }},
    logger: silentLogger(),
  });

  const answerOrFailure = await executor.execute({
    ...imageInput(), outputType: "text", languageModelId: "model-1",
    generationOptions: generationOptionsFrom({contextWindow: 16384, thinking: "off"}),
  });

  assert.ok(answerOrFailure.isOk());
  assert.deepEqual(configs, [{numCtx: 16384, think: false}]);
});

test("a missing capability becomes the capabilityMissing failure", async () => {
  const executor = new GenkitPromptExecutor({ai: {} as never, languageModelResolver: fakeResolver(), logger: silentLogger()});

  const answerOrFailure = await executor.execute({...imageInput(), languageModelId: "model-1"});

  assert.ok(answerOrFailure.isErr());
  assert.equal(answerOrFailure.error.code, "capabilityMissing");
});

function imageInput(): PromptNodeInput {
  return {
    teamId: "team-1", generationOptions: defaultGenerationOptions, instruction: "Erstelle ein Logo.",
    outputType: "image", choices: [], structuredFields: [], mediaUrls: [],
  };
}

function fakeResolver(): GenkitLanguageModelResolver {
  return {async resolve() {
    return {
      ai: {} as never, model: "text-only" as never, logContext: {}, generationConfig: {configFor: () => ({})},
      capabilities: {textGeneration: true, imageInput: false, structuredOutput: false, toolCalling: false, imageGeneration: false},
    };
  }};
}

function silentLogger(): ApplicationLogger {
  return {readableInfo() {}, readableError() {}, info() {}, error() {}, exception() {}};
}
