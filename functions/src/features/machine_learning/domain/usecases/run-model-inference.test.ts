import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelTensor} from "../entities/model-tensor.js";
import {type ModelArtifactReader} from "../repositories/model-artifact-reader.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {
  type ModelInferenceRuntime,
  type ModelRuntimeRequest,
} from "../repositories/model-inference-runtime.js";
import {RunModelInference} from "./run-model-inference.js";

test("loads an available model and returns validated outputs", async () => {
  const runtime = new RecordingRuntime();
  const useCase = new RunModelInference(new Catalog(), new ArtifactReader(), runtime);

  const outputs = await useCase.execute({
    teamId: "team-1",
    modelId: "identity",
    inputs: [tensor("input", [1], [12])],
  });

  assert.deepEqual(outputs[0].shape, [1]);
  assert.equal(runtime.request?.model.id, "identity");
  assert.deepEqual([...runtime.request!.artifact], [1, 2, 3, 4]);
});

test("rejects a tensor that violates the model contract before execution", async () => {
  const runtime = new RecordingRuntime();
  const useCase = new RunModelInference(new Catalog(), new ArtifactReader(), runtime);

  await assert.rejects(
    () => useCase.execute({teamId: "team-1", modelId: "identity", inputs: [tensor("input", [2], [1, 2])]}),
    /Eingabe-Tensor input/,
  );
  assert.equal(runtime.request, undefined);
});

test("rejects runtime outputs that violate the model contract", async () => {
  const runtime = new RecordingRuntime(tensor("unexpected", [1], [12]));
  const useCase = new RunModelInference(new Catalog(), new ArtifactReader(), runtime);

  await assert.rejects(
    () => useCase.execute({teamId: "team-1", modelId: "identity", inputs: [tensor("input", [1], [12])]}),
    /Ausgabe-Tensoren/,
  );
});

class Catalog implements ModelCatalog {
  async save(): Promise<void> {}

  async listAvailableFor(): Promise<readonly ModelCatalogEntry[]> {
    return [entry()];
  }

  async findAvailableFor(): Promise<ModelCatalogEntry | null> {
    return entry();
  }
}

class ArtifactReader implements ModelArtifactReader {
  async read(): Promise<Uint8Array> {
    return Uint8Array.from([1, 2, 3, 4]);
  }
}

class RecordingRuntime implements ModelInferenceRuntime {
  request: ModelRuntimeRequest | undefined;

  constructor(private readonly output = tensor("output", [1], [12])) {}

  async execute(request: ModelRuntimeRequest): Promise<readonly ModelTensor[]> {
    this.request = request;
    return [this.output];
  }
}

function tensor(name: string, shape: readonly number[], values: readonly number[]): ModelTensor {
  return {name, dataType: "uint8", shape, bytes: Uint8Array.from(values)};
}

function entry(): ModelCatalogEntry {
  return {
    id: "identity",
    title: "Identität",
    description: "Gibt den Eingang zurück.",
    tags: ["test"],
    scope: {type: "system"},
    runtime: "onnx",
    artifactReference: {
      artifactId: "identity-artifact",
      versionId: "1",
      format: "onnx",
      contentType: "application/onnx",
      sizeBytes: 4,
      sha256: "0000000000000000000000000000000000000000000000000000000000000000",
    },
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], preprocessing: []}],
      outputs: [{name: "output", dataType: "uint8", shape: [1], semantic: "test.output", postprocessing: []}],
    },
  };
}
