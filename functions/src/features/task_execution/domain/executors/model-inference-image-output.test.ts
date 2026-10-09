import assert from "node:assert/strict";
import test from "node:test";
import {modelInferenceNodeExecutor} from "./model-inference-node-executor.js";

const png = {dataBase64: "iVBORw0KGgo=", contentType: "image/png", fileName: "maske.png"};

test("stores an image output as a team file and returns it as media", async () => {
  const written: {fileName: string; contentType: string; content: Uint8Array}[] = [];

  const result = await modelInferenceNodeExecutor.execute(node(), runContext(png, written) as never);

  assert.equal(written[0]?.fileName, "maske.png");
  assert.equal(written[0]?.contentType, "image/png");
  assert.deepEqual(Array.from(written[0]?.content ?? []), Array.from(Buffer.from(png.dataBase64, "base64")));
  assert.equal(result.outputs.maske?.type, "media");
});

test("rejects an image output without an image content type", async () => {
  await assert.rejects(
    modelInferenceNodeExecutor.execute(node(), runContext({...png, contentType: "audio/wav"}, []) as never),
    /Bildausgabe des Modells hat keinen Bild-Content-Type/,
  );
});

function node() {
  return {
    id: "segmentierung", primitive: "modelInference",
    config: {primitive: "modelInference", modelId: "segmenter", inputMappings: []},
  } as never;
}

function runContext(value: unknown, written: {fileName: string; contentType: string; content: Uint8Array}[]) {
  return {
    teamId: "team-1",
    templateExpressionResolver: {resolveValue: () => undefined},
    teamFileStore: {
      async writeTeamFile(request: {fileName: string; contentType: string; content: Uint8Array}) {
        written.push(request);
        return {fileId: "datei-1", versionId: "v1", displayName: request.fileName, contentType: request.contentType, sizeBytes: request.content.length};
      },
    },
    modelInference: {
      async execute() {
        return {
          modelId: "segmenter",
          outputs: [{
            name: "mask", semantic: "segmentation.mask", dataType: "uint8" as const, shape: [1], bytes: Uint8Array.from([1]),
            workflowOutput: {name: "maske", type: "image" as const, mapping: "$tensor"},
            value,
          }],
        };
      },
    },
  };
}
