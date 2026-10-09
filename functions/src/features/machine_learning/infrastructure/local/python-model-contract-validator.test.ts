import assert from "node:assert/strict";
import test from "node:test";
import {type ModelContract} from "../../domain/entities/model-contract.js";
import {
  PythonModelContractValidator,
  type PythonContractValidationClient,
} from "./python-model-contract-validator.js";

test("sends the whole contract to the Python sidecar for validation", async () => {
  const client = new Client();
  const validator = new PythonModelContractValidator("http://novooa-ml:8081", client);

  await validator.validate(contract("image.resize", "tensor.topK"));

  assert.equal(client.url, "http://novooa-ml:8081/v1/contract-validations");
  assert.deepEqual(client.body, {contract: contract("image.resize", "tensor.topK")});
});

test("rejects a contract with the sidecar's explanation before installation", async () => {
  const client = new Client("Eingang image: audio.melSpectrogram erwartet audio, erhält image.");
  const validator = new PythonModelContractValidator("http://novooa-ml:8081", client);

  await assert.rejects(
    validator.validate(contract("audio.melSpectrogram", "tensor.topK")),
    /audio.melSpectrogram erwartet audio, erhält image/,
  );
});

class Client implements PythonContractValidationClient {
  url?: string;
  body?: unknown;

  constructor(private readonly rejection?: string) {}

  async post(url: string, body: unknown): Promise<unknown> {
    this.url = url;
    this.body = body;
    if (this.rejection !== undefined) throw new Error(this.rejection);
    return {status: "ok"};
  }
}

function contract(inputType: string, outputType: string): ModelContract {
  return {
    inputs: [{
      name: "image", source: "image", dataType: "float32", shape: [1],
      transformations: [{type: inputType, parameters: {}}],
    }],
    outputs: [{
      name: "scores", semantic: "test.scores", dataType: "float32", shape: [1],
      transformations: [{type: outputType, parameters: {}}],
      workflowOutput: {name: "scores", type: "json", mapping: "$tensor"},
    }],
  };
}
