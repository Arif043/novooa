import assert from "node:assert/strict";
import test from "node:test";
import {type ModelContract} from "../../domain/entities/model-contract.js";
import {
  PythonModelContractValidator,
  type PythonTransformationCapabilityClient,
} from "./python-model-contract-validator.js";

test("accepts transformations exposed by the Python sidecar", async () => {
  const validator = new PythonModelContractValidator("http://novooa-ml:8081", new Client());

  await validator.validate(contract("image.resize", "tensor.topK"));
});

test("rejects an unsupported transformation before installation", async () => {
  const validator = new PythonModelContractValidator("http://novooa-ml:8081", new Client());

  await assert.rejects(validator.validate(contract("image.unsupported", "tensor.topK")), /image.unsupported/);
});

class Client implements PythonTransformationCapabilityClient {
  async get(url: string): Promise<unknown> {
    assert.equal(url, "http://novooa-ml:8081/v1/transformation-capabilities");
    return {
      inputTransformationTypes: ["image.resize"],
      outputTransformationTypes: ["tensor.topK"],
    };
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
