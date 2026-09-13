import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelTensor} from "../../domain/entities/model-tensor.js";
import {LocalOnnxInferenceRuntime} from "./local-onnx-inference-runtime.js";
import {type PythonOnnxWorker, type PythonOnnxWorkerRequest} from "./python-onnx-worker.js";

test("passes supplied artifact bytes and expected output names to the Python worker", async () => {
  const worker = new Worker();
  const runtime = new LocalOnnxInferenceRuntime(worker);

  await runtime.execute({model: entry(), artifact: Uint8Array.from([9]), inputs: [tensor()]});

  assert.deepEqual([...worker.request!.artifact], [9]);
  assert.deepEqual(worker.request!.outputNames, ["output"]);
  assert.equal(worker.request!.inputs[0].name, "input");
});

class Worker implements PythonOnnxWorker {
  request: PythonOnnxWorkerRequest | undefined;

  async execute(request: PythonOnnxWorkerRequest): Promise<readonly ModelTensor[]> {
    this.request = request;
    return [tensor("output")];
  }
}

function tensor(name = "input"): ModelTensor {
  return {name, dataType: "uint8", shape: [1], bytes: Uint8Array.from([1])};
}

function entry(): ModelCatalogEntry {
  return {
    id: "model", title: "Modell", description: "Testmodell", tags: ["test"],
    scope: {type: "system"}, runtime: "onnx",
    artifactReference: {
      artifactId: "artifact", versionId: "1", format: "onnx", contentType: "application/onnx",
      sizeBytes: 4, sha256: "0000000000000000000000000000000000000000000000000000000000000000",
    },
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], preprocessing: []}],
      outputs: [{name: "output", dataType: "uint8", shape: [1], semantic: "test.output", postprocessing: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}
