import assert from "node:assert/strict";
import test from "node:test";
import {speechToTextNodeExecutor, textToSpeechNodeExecutor} from "./speech-node-executor.js";

type SpeechCall = {teamId: string; languageModelId: string; text: string; voiceId?: string};

function nodeWith(config: Record<string, unknown>) {
  return {
    id: "tts", primitive: "textToSpeech",
    config: {primitive: "textToSpeech", modelId: "", inputMappings: [], ...config},
  } as never;
}

function runContext(calls: SpeechCall[], withSynthesizer = true) {
  const writes: Array<{fileName: string; contentType: string; content: Uint8Array}> = [];
  const context = {
    teamId: "team-1",
    templateExpressionResolver: {
      resolveText: (template: string) => template.replace("{{name}}", "Anna"),
      resolveValue: () => "",
    },
    teamFileStore: {
      writeTeamFile: async (input: {fileName: string; contentType: string; content: Uint8Array}) => {
        writes.push(input);
        return {fileId: "f1", versionId: "v1", displayName: input.fileName, contentType: input.contentType, sizeBytes: input.content.length};
      },
    },
    speechSynthesizer: withSynthesizer ? {
      synthesize: async (request: SpeechCall) => {
        calls.push(request);
        return {bytes: new Uint8Array([1, 2]), contentType: "audio/wav", fileExtension: "wav"};
      },
    } : undefined,
  };
  return {context: context as never, writes};
}

test("speaks the resolved text with the chosen language model and voice", async () => {
  const calls: SpeechCall[] = [];
  const {context, writes} = runContext(calls);

  const result = await textToSpeechNodeExecutor.execute(
    nodeWith({languageModelId: "lm-1", speechText: "Hallo {{name}}", voiceId: "Puck"}), context,
  );

  assert.deepEqual(calls, [{teamId: "team-1", languageModelId: "lm-1", text: "Hallo Anna", voiceId: "Puck"}]);
  assert.equal(writes[0].fileName, "sprach-ausgabe.wav");
  assert.equal(result.outputs.value.type, "audio");
  assert.equal((result.outputs.value as {value: {fileId: string}}).value.fileId, "f1");
});

test("an empty voice falls back to the provider default", async () => {
  const calls: SpeechCall[] = [];
  const {context} = runContext(calls);

  await textToSpeechNodeExecutor.execute(nodeWith({languageModelId: "lm-1", speechText: "Hallo", voiceId: " "}), context);

  assert.equal(calls[0].voiceId, undefined);
});

test("fails readably when speech synthesis is not available in the environment", async () => {
  const {context} = runContext([], false);

  await assert.rejects(
    textToSpeechNodeExecutor.execute(nodeWith({languageModelId: "lm-1", speechText: "Hallo"}), context),
    /nicht verfügbar/,
  );
});

test("without a language model the ONNX inference path is used", async () => {
  const requests: Array<{modelId: string}> = [];
  const {context} = runContext([]);
  const onnxContext = {
    ...(context as object),
    modelInference: {execute: async (request: {modelId: string}) => { requests.push(request); return {modelId: request.modelId, outputs: []}; }},
  } as never;

  const result = await textToSpeechNodeExecutor.execute(nodeWith({modelId: "onnx-tts"}), onnxContext);

  assert.deepEqual(requests.map((request) => request.modelId), ["onnx-tts"]);
  assert.deepEqual(result.outputs, {});
});

function sttNode(config: Record<string, unknown>) {
  return {
    id: "stt", primitive: "speechToText",
    config: {primitive: "speechToText", modelId: "", inputMappings: [], ...config},
  } as never;
}

function sttContext(transcribed: Array<Record<string, unknown>>, reference: unknown = {fileId: "f1", versionId: "v1"}) {
  return {
    teamId: "team-1",
    templateExpressionResolver: {resolveValue: () => reference},
    fileContentReader: {
      readTeamFileContent: async () => ({content: new Uint8Array([1]), displayName: "a.wav", contentType: "audio/wav", sizeBytes: 1}),
    },
    speechTranscriber: {transcribe: async (request: Record<string, unknown>) => { transcribed.push(request); return "Hallo Welt"; }},
  } as never;
}

test("transcribes the referenced audio file with the chosen language model", async () => {
  const transcribed: Array<Record<string, unknown>> = [];

  const result = await speechToTextNodeExecutor.execute(
    sttNode({languageModelId: "lm-1", audioTemplate: "{{aufnahme.value}}"}), sttContext(transcribed),
  );

  assert.deepEqual(result.outputs.value, {type: "string", value: "Hallo Welt"});
  assert.equal(transcribed[0].languageModelId, "lm-1");
  assert.equal(transcribed[0].teamId, "team-1");
});

test("transcription without an audio reference fails readably", async () => {
  await assert.rejects(
    speechToTextNodeExecutor.execute(sttNode({languageModelId: "lm-1"}), sttContext([], "")),
    /keine Audiodatei zugeordnet/,
  );
});

test("speech to text without a language model keeps the ONNX path", async () => {
  const requests: string[] = [];
  const context = {
    ...(sttContext([]) as object),
    modelInference: {execute: async (request: {modelId: string}) => { requests.push(request.modelId); return {modelId: request.modelId, outputs: []}; }},
  } as never;

  await speechToTextNodeExecutor.execute(sttNode({modelId: "whisper"}), context);

  assert.deepEqual(requests, ["whisper"]);
});
