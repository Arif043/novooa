import assert from "node:assert/strict";
import test from "node:test";
import {createGenkitPromptNodeExecutor} from "./genkit-prompt-node-executor.js";
import {succeeded} from "../../../domain/executors/node-executor-test-support.js";

test("provides a media template value as a Genkit media part", async () => {
  const prompts: unknown[] = [];
  await createGenkitPromptNodeExecutor(fakeAi(prompts)).execute(
    executorInput().node,
    runContext() as never,
  );
  assert.deepEqual(prompts, [[
    {text: "Kannst du das Bild sehen?"},
    {media: {url: "data:image/png;base64,iVBORw0KGgo="}},
  ]]);
});

test("persists a generated image as a media value", async () => {
  const output = succeeded(await createGenkitPromptNodeExecutor(imageAi()).execute(
    imageExecutorInput().node,
    imageRunContext() as never,
  ));
  assert.deepEqual(output.outputs.value, {
    type: "media",
    value: {
      fileId: "file-2",
      versionId: "version-2",
      displayName: "generiertes-bild-prompt-2.png",
      contentType: "image/png",
      sizeBytes: 8,
    },
  });
});

test("uses the selected team language model for a text prompt", async () => {
  const models: unknown[] = [];
  const output = succeeded(await createGenkitPromptNodeExecutor(
    fakeAi([]),
    undefined,
    {
      async resolve() {
        return {
          ai: {
            async generate(input: {model: unknown}) {
              models.push(input.model);
              return {text: "Aus dem Teammodell."};
            },
          },
          model: "team-model" as never,
          capabilities: capabilities(),
          logContext: {provider: "test", model: "team-model"},
          generationConfig: {configFor: () => ({})},
        } as never;
      },
    },
  ).execute({
      ...executorInput().node,
      config: {...promptConfig(), languageModelId: "model-1"},
  }, runContext() as never));

  assert.equal(output.outputs.value?.value, "Aus dem Teammodell.");
  assert.deepEqual(models, ["team-model"]);
});

test("a selected model that cannot receive the supplied image is a failure value", async () => {
  const resultOrFailure = await createGenkitPromptNodeExecutor(
      fakeAi([]),
      undefined,
      {async resolve() {
        return {
          ai: fakeAi([]), model: "team-model" as never,
          capabilities: {...capabilities(), imageInput: false},
          logContext: {provider: "test", model: "team-model"},
          generationConfig: {configFor: () => ({})},
        };
      }},
    ).execute({
        ...executorInput().node,
        config: {...promptConfig(), languageModelId: "model-1"},
    }, runContext() as never);

  const failure = resultOrFailure._unsafeUnwrapErr();
  assert.equal(failure.code, "capabilityMissing");
  assert.match(failure.message, /keine Bildeingaben/);
});

function executorInput() {
  return {
    context: "",
    node: {
      id: "prompt-1",
      primitive: "prompt" as const,
      title: "Bild prüfen",
      description: "",
      outputs: [{key: "value", name: "bildPruefen", showOnCanvas: true}],
      config: promptConfig(),
    },
  };
}

function promptConfig() {
  return {
    primitive: "prompt" as const,
    instruction: "Kannst du das Bild sehen? {{bild.value}}",
    outputType: "text" as const,
    choices: [],
    structuredFields: [],
    firstChoice: "",
    secondChoice: "",
    attachments: [],
    knowledgeAttachments: [],
    skillAttachments: [],
  };
}

function imageExecutorInput() {
  return {
    context: "",
    node: {...executorInput().node, id: "prompt-2", config: {...promptConfig(), outputType: "image" as const}},
  };
}

function mediaReference() {
  return {
    fileId: "file-1",
    versionId: "version-1",
    displayName: "bild.png",
    contentType: "image/png",
    sizeBytes: 8,
  };
}

function runContext() {
  return {
    context: "",
    templateExpressionResolver: {
      resolveText: (value: string) => value,
      resolveTextWithoutMediaReferences: (value: string) => value.replace("{{bild.value}}", ""),
      resolveMediaReferences: () => [mediaReference()],
    },
    teamId: "team-1",
    fileContentReader: {
      async readTeamFileContent() {
        return {
          content: Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
          displayName: "bild.png",
          contentType: "image/png",
          sizeBytes: 8,
        };
      },
    },
    teamFileStore: {},
  };
}

function imageRunContext() {
  return {
    ...runContext(),
    teamFileStore: {
      async writeTeamFile(input: {fileName: string; contentType: string; content: Uint8Array}) {
        return {
          fileId: "file-2", versionId: "version-2",
          storagePath: "teams/team-1/files/file-2/versions/version-2/bild.png",
          displayName: input.fileName, contentType: input.contentType,
          sizeBytes: input.content.byteLength, folderId: null, ownerUid: "system", isNewFile: true,
        };
      },
    },
  };
}

function fakeAi(prompts: unknown[]) {
  return {
    async generate(input: {prompt: unknown}) {
      prompts.push(input.prompt);
      return {text: "Ja."};
    },
  } as never;
}

function imageAi() {
  return {
    async generate() {
      return {media: {url: "data:image/png;base64,iVBORw0KGgo="}};
    },
  } as never;
}

function capabilities() {
  return {
    textGeneration: true,
    imageInput: true,
    structuredOutput: true,
    toolCalling: false,
    imageGeneration: false,
  };
}
