import assert from "node:assert/strict";
import test from "node:test";
import {
  executePromptNode,
  type PromptNodeInput,
} from "./prompt-node-executor.js";

test("returns only a data URL for an image prompt", async () => {
  const generatedImage = "data:image/png;base64,aW1hZ2U=";
  const calls: Array<{config?: unknown}> = [];

  const output = await executePromptNode(fakeAi(generatedImage, calls), imageInput());

  assert.equal(output.answer, generatedImage);
  assert.deepEqual(output.outputs, {
    dataUrl: {type: "string", value: generatedImage},
  });
  assert.deepEqual(calls[0]?.config, {responseModalities: ["IMAGE"]});
});

test("rejects an image response without a data URL", async () => {
  await assert.rejects(
    executePromptNode(fakeAi("https://example.com/image.png", []), imageInput()),
    /keine Bild-Data-URL/,
  );
});

function imageInput(): PromptNodeInput {
  return {
    instruction: "Erstelle ein Logo.",
    context: "",
    outputType: "image",
    choices: [],
    structuredFields: [],
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
