import assert from "node:assert/strict";
import {Readable} from "node:stream";
import test from "node:test";
import {type ModelCatalogEntry} from "../domain/entities/model-catalog-entry.js";
import {type ModelTensor} from "../domain/entities/model-tensor.js";
import {type ModelRuntimeOutput} from "../domain/repositories/model-inference-runtime.js";
import {type ModelBundle, type ModelBundleFile} from "./model-artifact-bundle.js";
import {type ModelBundleSource, type ModelBundleSources} from "./model-bundle-sources.js";
import {
  BundleFilesMissingError,
  ModelNotLoadedError,
  type PythonInferenceSidecar,
  SidecarOnnxInferenceRuntime,
} from "./python-inference-sidecar.js";

test("loads a model once by reference before reusing the sidecar session", async () => {
  const sidecar = new Sidecar();
  const runtime = new SidecarOnnxInferenceRuntime(sidecar, new Sources("global"));

  await runtime.execute(request());
  await runtime.execute(request());

  assert.equal(sidecar.loads.length, 1);
  assert.equal(sidecar.loads[0]?.source, "global");
  assert.equal(sidecar.inferences, 2);
});

test("reloads an evicted sidecar session", async () => {
  const sidecar = new Sidecar();
  const runtime = new SidecarOnnxInferenceRuntime(sidecar, new Sources("global"));
  await runtime.execute(request());
  sidecar.evicted = true;

  await runtime.execute(request());

  assert.equal(sidecar.loads.length, 2);
});

test("uploads only the files the ML service misses for a team model and loads again", async () => {
  const sidecar = new Sidecar(["model.onnx.data"]);
  const sources = new Sources("team");
  const runtime = new SidecarOnnxInferenceRuntime(sidecar, sources);

  await runtime.execute(request(withWeights()));

  assert.deepEqual(sidecar.uploads, ["model.onnx.data"]);
  assert.deepEqual(sources.read, ["model-artifacts/model/versions/one/model.onnx.data"]);
  assert.equal(sidecar.loads.length, 2);
});

test("does not upload global models when files are missing", async () => {
  const sidecar = new Sidecar(["model.onnx"]);
  const runtime = new SidecarOnnxInferenceRuntime(sidecar, new Sources("global"));

  await assert.rejects(runtime.execute(request()), BundleFilesMissingError);
  assert.deepEqual(sidecar.uploads, []);
});

test("prefetches only global models", async () => {
  const sidecar = new Sidecar();

  await new SidecarOnnxInferenceRuntime(sidecar, new Sources("global")).prefetch(entry());
  await new SidecarOnnxInferenceRuntime(sidecar, new Sources("team")).prefetch(entry());

  assert.equal(sidecar.prefetches, 1);
});

class Sidecar implements PythonInferenceSidecar {
  loads: {key: string; source: ModelBundleSource}[] = [];
  uploads: string[] = [];
  prefetches = 0;
  inferences = 0;
  evicted = false;

  constructor(private missing: readonly string[] = []) {}

  async load(bundle: ModelBundle, source: ModelBundleSource): Promise<void> {
    this.loads.push({key: bundle.key, source});
    if (this.missing.length > 0) throw new BundleFilesMissingError(this.missing);
  }

  async prefetch(): Promise<void> {
    this.prefetches += 1;
  }

  async upload(_bundle: ModelBundle, file: ModelBundleFile): Promise<void> {
    this.uploads.push(file.path);
    this.missing = this.missing.filter((path) => path !== file.path);
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

class Sources implements ModelBundleSources {
  read: string[] = [];

  constructor(private readonly source: ModelBundleSource) {}

  sourceOf(): ModelBundleSource {
    return this.source;
  }

  teamFileContent(file: ModelBundleFile): Readable {
    this.read.push(file.storePath);
    return Readable.from([Buffer.from("x")]);
  }
}

function request(model = entry()) {
  return {model, inputs: [tensor("input")]};
}

function tensor(name: string): ModelTensor {
  return {name, dataType: "uint8", shape: [1], bytes: Uint8Array.from([1])};
}

function withWeights(): ModelCatalogEntry {
  const model = entry();
  return {...model, artifactReference: {...model.artifactReference, externalData: [{name: "model.onnx.data", sizeBytes: 1, sha256: "1".repeat(64)}]}};
}

function entry(): ModelCatalogEntry {
  return {
    id: "model", title: "Modell", description: "Test", task: "image-classification", languages: [], tags: ["test"],
    scope: {type: "system"}, runtime: "onnx", artifactReference: {
      artifactId: "model", versionId: "one", format: "onnx", contentType: "application/onnx", sizeBytes: 1,
      sha256: "0".repeat(64),
    },
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: []}],
      outputs: [{name: "output", semantic: "test", dataType: "uint8", shape: [1], transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}
