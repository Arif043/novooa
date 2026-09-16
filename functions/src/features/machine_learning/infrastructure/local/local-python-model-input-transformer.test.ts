import assert from "node:assert/strict";
import test from "node:test";
import {type ModelInputTransformationRequest} from "../../domain/repositories/model-input-transformer.js";
import {type PythonJsonProcess} from "./local-python-process.js";
import {LocalPythonModelInputTransformer} from "./local-python-model-input-transformer.js";

test("sends image bytes and transformations instructions to the Python process", async () => {
  const process = new Process();
  const transformer = new LocalPythonModelInputTransformer(process);

  const tensor = await transformer.transform(imageRequest());

  assert.equal(tensor.name, "image");
  assert.equal(process.payload?.input.transformations[0].type, "image.resize");
  assert.equal(process.payload?.source.contentType, "image/png");
});

test("returns tensor sources without starting Python when no transformations is needed", async () => {
  const process = new Process();
  const transformer = new LocalPythonModelInputTransformer(process);
  const tensor = await transformer.transform(tensorRequest());

  assert.equal(tensor.name, "tensor");
  assert.equal(process.calls, 0);
});

class Process implements PythonJsonProcess {
  calls = 0;
  payload: {input: {transformations: Array<{type: string}>}; source: {contentType: string}} | undefined;

  async execute(value: string): Promise<string> {
    this.calls += 1;
    this.payload = JSON.parse(value) as typeof this.payload;
    return JSON.stringify({
      tensor: {name: "image", dataType: "uint8", shape: [1], dataBase64: "AQ=="},
    });
  }
}

function imageRequest(): ModelInputTransformationRequest {
  return {
    input: {
      name: "image", source: "image", dataType: "uint8", shape: [1],
      transformations: [{type: "image.resize", parameters: {width: 1, height: 1}}],
    },
    source: {name: "image", type: "image", contentType: "image/png", bytes: Uint8Array.from([1])},
  };
}

function tensorRequest(): ModelInputTransformationRequest {
  return {
    input: {name: "tensor", source: "tensor", dataType: "uint8", shape: [1], transformations: []},
    source: {
      name: "tensor", type: "tensor",
      tensor: {name: "tensor", dataType: "uint8", shape: [1], bytes: Uint8Array.from([1])},
    },
  };
}
