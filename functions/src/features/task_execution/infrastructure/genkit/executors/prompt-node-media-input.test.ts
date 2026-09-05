import assert from "node:assert/strict";
import test from "node:test";
import {createGenkitPromptNodeExecutor} from "./genkit-prompt-executor.js";

test("provides a direct media value as a Genkit media part", async () => {
  const prompts: unknown[] = [];
  await createGenkitPromptNodeExecutor(fakeAi(prompts)).execute(
    executorInput(),
    runContext() as never,
  );
  assert.deepEqual(prompts, [[
    {text: "Kannst du das Bild sehen?"},
    {media: {url: "data:image/png;base64,iVBORw0KGgo="}},
  ]]);
});

test("persists a generated image as a media value", async () => {
  const output = await createGenkitPromptNodeExecutor(imageAi()).execute(
    imageExecutorInput(),
    imageRunContext() as never,
  );
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

function executorInput() {
  return {
    context: "",
    node: {
      id: "prompt-1",
      primitive: "prompt" as const,
      title: "Bild prüfen",
      description: "",
      referenceName: "bildPruefen",
      config: promptConfig(),
    },
    parentOutputs: [mediaParentOutput()],
  };
}

function promptConfig() {
  return {
    primitive: "prompt" as const,
    instruction: "Kannst du das Bild sehen?",
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
    parentOutputs: [],
  };
}

function mediaParentOutput() {
  return {
    nodeId: "media-1",
    outputName: "value",
    value: {
      type: "media" as const,
      value: {
        fileId: "file-1",
        versionId: "version-1",
        displayName: "bild.png",
        contentType: "image/png",
        sizeBytes: 8,
      },
    },
  };
}

function runContext() {
  return {
    resolveTemplates: (value: string) => value,
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
