import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../domain/entities/model-catalog-entry.js";
import {type ModelTensor} from "../domain/entities/model-tensor.js";
import {ModelNotLoadedError, type PythonInferenceSidecar, SidecarOnnxInferenceRuntime} from "./python-inference-sidecar.js";

test("loads an artifact once before reusing the sidecar session", async () => {
  const sidecar = new Sidecar();
  const runtime = new SidecarOnnxInferenceRuntime(sidecar);

  await runtime.execute(request());
  await runtime.execute(request());

  assert.equal(sidecar.loads, 1);
  assert.equal(sidecar.inferences, 2);
});

test("reloads an evicted sidecar session", async () => {
  const sidecar = new Sidecar();
  const runtime = new SidecarOnnxInferenceRuntime(sidecar);
  await runtime.execute(request());
  sidecar.evicted = true;

  await runtime.execute(request());

  assert.equal(sidecar.loads, 2);
});

class Sidecar implements PythonInferenceSidecar {
  loads = 0;
  inferences = 0;
  evicted = false;

  async load(): Promise<void> { this.loads += 1; }

  async infer(): Promise<readonly ModelTensor[]> {
    this.inferences += 1;
    if (this.evicted) {
      this.evicted = false;
      throw new ModelNotLoadedError();
    }
    return [tensor("output")];
  }
}

function request() {
  return {model: entry(), artifact: Uint8Array.from([1]), inputs: [tensor("input")]};
}

function tensor(name: string): ModelTensor {
  return {name, dataType: "uint8", shape: [1], bytes: Uint8Array.from([1])};
}

function entry(): ModelCatalogEntry {
  return {
    id: "model", title: "Modell", description: "Test", tags: ["test"],
    scope: {type: "system"}, runtime: "onnx", artifactReference: {
      artifactId: "model", versionId: "one", format: "onnx", contentType: "application/onnx", sizeBytes: 1,
      sha256: "0000000000000000000000000000000000000000000000000000000000000000",
    },
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], preprocessing: []}],
      outputs: [{name: "output", semantic: "test", dataType: "uint8", shape: [1], postprocessing: []}],
    },
  };
}
