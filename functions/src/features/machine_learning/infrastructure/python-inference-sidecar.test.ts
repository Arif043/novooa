import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../domain/entities/model-catalog-entry.js";
import {type ModelRuntimeResource} from "../domain/entities/model-runtime-resource.js";
import {type ModelTensor} from "../domain/entities/model-tensor.js";
import {ModelNotLoadedError, type PythonInferenceSidecar, SidecarOnnxInferenceRuntime} from "./python-inference-sidecar.js";
import {type ModelRuntimeOutput} from "../domain/repositories/model-inference-runtime.js";

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

test("loads resources with the model bundle and isolates its cache key", async () => {
  const sidecar = new Sidecar();
  const runtime = new SidecarOnnxInferenceRuntime(sidecar);

  await runtime.execute({...request(), resources: [resource("voice", 1)]});
  await runtime.execute({...request(), resources: [resource("voice", 2)]});

  assert.equal(sidecar.loads, 2);
  assert.equal(sidecar.resources[0]?.[0]?.bytes[0], 1);
  assert.equal(sidecar.resources[1]?.[0]?.bytes[0], 2);
});

class Sidecar implements PythonInferenceSidecar {
  loads = 0;
  inferences = 0;
  evicted = false;
  resources: ModelRuntimeResource[][] = [];

  async load(request: Parameters<PythonInferenceSidecar["load"]>[0]): Promise<void> {
    this.loads += 1;
    this.resources.push([...request.resources]);
  }

  async infer(): Promise<readonly ModelRuntimeOutput[]> {
    this.inferences += 1;
    if (this.evicted) {
      this.evicted = false;
      throw new ModelNotLoadedError();
    }
    const tensorOutput = tensor("output");
    return [{...tensorOutput, tensor: tensorOutput, transformationValues: {tensor: []}}];
  }
}

function request() {
  return {model: entry(), artifact: Uint8Array.from([1]), inputs: [tensor("input")]};
}

function tensor(name: string): ModelTensor {
  return {name, dataType: "uint8", shape: [1], bytes: Uint8Array.from([1])};
}

function resource(name: string, value: number): ModelRuntimeResource {
  return {
    name,
    contentType: "application/octet-stream",
    sha256: `${value}`.padStart(64, "0"),
    bytes: Uint8Array.from([value]),
  };
}

function entry(): ModelCatalogEntry {
  return {
    id: "model", title: "Modell", description: "Test", tags: ["test"],
    scope: {type: "system"}, runtime: "onnx", artifactReference: {
      artifactId: "model", versionId: "one", format: "onnx", contentType: "application/onnx", sizeBytes: 1,
      sha256: "0000000000000000000000000000000000000000000000000000000000000000",
    },
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: []}],
      outputs: [{name: "output", semantic: "test", dataType: "uint8", shape: [1], transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}
