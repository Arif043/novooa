import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import assert from "node:assert/strict";
import {mkdtemp, readFile, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type TeamModelCatalog} from "../../domain/repositories/model-catalog.js";
import {systemModelEntry, systemModelManifestFromUnknown} from "../cli/system-model-manifest.js";
import {LocalModelArtifactPublisher} from "./local-model-artifact-publisher.js";
import {LocalModelArtifactUploadStore} from "./local-model-artifact-upload-store.js";
import {modelCatalogRoutes} from "./local-model-catalog-routes.js";
import {CacheSystemModel} from "../../domain/usecases/cache-system-model.js";
import {ModelCacheJobs} from "./model-cache-jobs.js";
import {type ModelContractValidator} from "./python-model-contract-validator.js";
import {type RuntimeSystemModel, type RuntimeSystemModelCatalog} from "./runtime-system-model-catalog.js";

test("installs a team-scoped ONNX model from a manifest and lists it", async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-import-"));
  const catalog = new Catalog();
  const handler = testingRoutes(modelCatalogRoutes, {
    catalog: catalog,
    artifactPublisher: new LocalModelArtifactPublisher(directory),
    uploadStore: new LocalModelArtifactUploadStore(directory),
    contractValidator: new Validator(),
    notifier: new LocalRuntimeRealtimeNotifier(),
  }, {teamId: "team-1", logger: new Logger()});

  try {
    const importRequest = await handler.handle({
      method: "POST",
      url: "/v1/ml-models/imports",
      body: {manifest: manifest()},
    });
    const imported = await upload(handler, importRequest);
    const listed = await handler.handle({method: "GET", url: "/v1/ml-models", body: {}});

    assert.equal(imported?.statusCode, 201);
    assert.equal(catalog.entries[0]?.scope.type, "team");
    assert.deepEqual(listed?.body, {items: catalog.entries});
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
});

test("lists global models and prefetches one in the background without copying it", async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-global-model-"));
  const catalog = new Catalog();
  const model = globalModel();
  const prefetched: ModelCatalogEntry[] = [];
  const systemModelCatalog = new GlobalCatalog(model);
  const cacheSystemModel = new CacheSystemModel(catalog, systemModelCatalog, new Validator(), {
    prefetch: async (entry) => { prefetched.push(entry); },
  });
  const modelCache = {cacheSystemModel, jobs: new ModelCacheJobs("team-1", cacheSystemModel, new LocalRuntimeRealtimeNotifier(), new Logger())};
  const handler = testingRoutes(modelCatalogRoutes, {
    catalog: catalog,
    artifactPublisher: new LocalModelArtifactPublisher(directory),
    uploadStore: new LocalModelArtifactUploadStore(directory),
    contractValidator: new Validator(),
    notifier: new LocalRuntimeRealtimeNotifier(),
  }, {teamId: "team-1", logger: new Logger(), systemModelCatalog, modelCache});

  try {
    const listed = await handler.handle({method: "GET", url: "/v1/ml-models/catalog", body: {}});
    const started = await handler.handle({method: "POST", url: "/v1/ml-models/catalog/example-model/cache", body: {}});
    const missing = await handler.handle({method: "POST", url: "/v1/ml-models/catalog/unknown/cache", body: {}});
    await waitFor(() => catalog.entries.length === 1);
    const again = await handler.handle({method: "POST", url: "/v1/ml-models/catalog/example-model/cache", body: {}});
    const status = await handler.handle({method: "GET", url: "/v1/ml-models/cache-status", body: {}});
    const local = await handler.handle({method: "GET", url: "/v1/ml-models", body: {}});

    assert.deepEqual(listed?.body, {items: [model.entry]});
    assert.deepEqual(started, {statusCode: 202, body: {modelId: "example-model", state: "downloading"}});
    assert.equal(missing?.statusCode, 404);
    assert.deepEqual(again, {statusCode: 200, body: {modelId: "example-model", state: "cached"}});
    assert.deepEqual(status?.body, {items: []});
    assert.deepEqual(catalog.entries[0]?.scope, {type: "team", teamId: "team-1"});
    assert.equal(catalog.entries[0]?.origin, "catalog");
    assert.equal((local?.body as {items: {origin?: string}[]}).items[0]?.origin, "catalog");
    assert.deepEqual(prefetched.map((entry) => entry.id), ["example-model"]);
    await assert.rejects(readFile(path.join(directory, "model-artifacts/example-model/versions/1/model.onnx")));
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
});

test("caching needs the global catalog", async () => {
  const handler = testingRoutes(modelCatalogRoutes, {
    catalog: new Catalog(),
    artifactPublisher: new LocalModelArtifactPublisher("/tmp/novooa-unused"),
    uploadStore: new LocalModelArtifactUploadStore("/tmp/novooa-unused"),
    contractValidator: new Validator(),
    notifier: new LocalRuntimeRealtimeNotifier(),
  }, {teamId: "team-1", logger: new Logger()});

  const response = await handler.handle({method: "POST", url: "/v1/ml-models/catalog/example-model/cache", body: {}});

  assert.equal(response?.statusCode, 503);
});

async function waitFor(condition: () => boolean): Promise<void> {
  for (let attempt = 0; attempt < 100 && !condition(); attempt += 1) {
    await new Promise((resolve) => setTimeout(resolve, 5));
  }
  assert.ok(condition(), "Der Hintergrund-Download ist nicht fertig geworden.");
}

test("rejects a manifest whose transformation is not supported by the Python runtime", async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-import-"));
  const handler = testingRoutes(modelCatalogRoutes, {
    catalog: new Catalog(),
    artifactPublisher: new LocalModelArtifactPublisher(directory),
    uploadStore: new LocalModelArtifactUploadStore(directory),
    contractValidator: new RejectingValidator(),
    notifier: new LocalRuntimeRealtimeNotifier(),
  }, {teamId: "team-1", logger: new Logger()});

  try {
    const importRequest = await handler.handle({
      method: "POST",
      url: "/v1/ml-models/imports",
      body: {manifest: manifest()},
    });
    const response = await upload(handler, importRequest);

    assert.equal(response?.statusCode, 400);
    assert.deepEqual(response?.body, {error: "Die Ausgabe-Transformation unknown.type wird von der lokalen Runtime nicht unterstützt."});
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
});

test("does not remove a model owned by another team", async () => {
  const handler = testingRoutes(modelCatalogRoutes, {
    catalog: new Catalog(),
    artifactPublisher: new LocalModelArtifactPublisher("/tmp/novooa-unused"),
    uploadStore: new LocalModelArtifactUploadStore("/tmp/novooa-unused"),
    contractValidator: new Validator(),
    notifier: new LocalRuntimeRealtimeNotifier(),
  }, {teamId: "team-1", logger: new Logger()});

  const response = await handler.handle({
    method: "DELETE",
    url: "/v1/ml-models/unknown",
    body: {},
  });

  assert.equal(response?.statusCode, 404);
});

test("removes the ONNX artifact with the local catalog entry", async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-import-"));
  const catalog = new Catalog();
  const handler = testingRoutes(modelCatalogRoutes, {
    catalog: catalog,
    artifactPublisher: new LocalModelArtifactPublisher(directory),
    uploadStore: new LocalModelArtifactUploadStore(directory),
    contractValidator: new Validator(),
    notifier: new LocalRuntimeRealtimeNotifier(),
  }, {teamId: "team-1", logger: new Logger()});

  try {
    const importRequest = await handler.handle({
      method: "POST",
      url: "/v1/ml-models/imports",
      body: {manifest: manifest()},
    });
    await upload(handler, importRequest);
    const removed = await handler.handle({method: "DELETE", url: "/v1/ml-models/example-model", body: {}});

    assert.equal(removed?.statusCode, 204);
    await assert.rejects(readFile(path.join(directory, "model-artifacts/example-model/versions/1/model.onnx")));
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
});

test("recovers an interrupted import with an existing local artifact", async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-import-"));
  const catalog = new Catalog();
  const handler = testingRoutes(modelCatalogRoutes, {
    catalog: catalog,
    artifactPublisher: new LocalModelArtifactPublisher(directory),
    uploadStore: new LocalModelArtifactUploadStore(directory),
    contractValidator: new Validator(),
    notifier: new LocalRuntimeRealtimeNotifier(),
  }, {teamId: "team-1", logger: new Logger()});
  const request = {
    method: "POST" as const,
    url: "/v1/ml-models/imports",
    body: {manifest: manifest()},
  };

  try {
    await upload(handler, await handler.handle(request));
    await catalog.removeTeamEntry("team-1", "example-model");

    const recovered = await upload(handler, await handler.handle(request));

    assert.equal(recovered?.statusCode, 201);
    assert.equal(catalog.entries.length, 1);
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
});

async function upload(
  handler: ReturnType<typeof testingRoutes>,
  importRequest: {body: unknown} | null,
) {
  const importId = (importRequest?.body as {importId?: unknown}).importId;
  assert.equal(typeof importId, "string");
  return handler.handleStream({
    method: "PUT",
    url: `/v1/ml-models/imports/${importId}/artifact`,
    headers: {"content-type": "application/onnx", "content-length": "4"},
    body: artifactContent(),
  });
}

async function* artifactContent(): AsyncIterable<Uint8Array> {
  yield Buffer.from("onnx");
}

class Catalog implements TeamModelCatalog {
  entries: ModelCatalogEntry[] = [];

  async save(entry: ModelCatalogEntry): Promise<void> {
    this.entries = [...this.entries.filter((item) => item.id !== entry.id), entry];
  }

  async listAvailableFor(): Promise<readonly ModelCatalogEntry[]> {
    return this.entries;
  }

  async findAvailableFor(_teamId: string, modelId: string): Promise<ModelCatalogEntry | null> {
    return this.entries.find((entry) => entry.id === modelId) ?? null;
  }

  async removeTeamEntry(_teamId: string, modelId: string): Promise<boolean> {
    const exists = this.entries.some((entry) => entry.id === modelId);
    this.entries = this.entries.filter((entry) => entry.id !== modelId);
    return exists;
  }
}

class Validator implements ModelContractValidator {
  async validate(): Promise<void> {}
}

class RejectingValidator implements ModelContractValidator {
  async validate(): Promise<void> {
    throw new Error("Die Ausgabe-Transformation unknown.type wird von der lokalen Runtime nicht unterstützt.");
  }
}

class GlobalCatalog implements RuntimeSystemModelCatalog {
  constructor(private readonly model: RuntimeSystemModel) {}

  async list(): Promise<readonly RuntimeSystemModel[]> {
    return [this.model];
  }

  async find(modelId: string): Promise<RuntimeSystemModel | null> {
    return modelId === this.model.entry.id ? this.model : null;
  }
}

class Logger implements ApplicationLogger {
  error(): void {}
  exception(): void {}
  info(): void {}
  readableError(): void {}
  readableInfo(): void {}
}

function manifest() {
  return {
    id: "example-model",
    title: "Beispielmodell",
    description: "Ein lokales Testmodell.",
    task: "image-classification",
    languages: [],
    tags: ["test"],
    artifact: {artifactId: "example-model", versionId: "1"},
    contract: {
      inputs: [{
        name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: [],
      }],
      outputs: [{
        name: "output", dataType: "uint8", shape: [1], semantic: "classification.scores", transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"},
      }],
    },
  };
}

function globalModel(): RuntimeSystemModel {
  return {
    entry: systemModelEntry(systemModelManifestFromUnknown(manifest()), {
      artifactId: "example-model",
      versionId: "1",
      format: "onnx",
      contentType: "application/onnx",
      sizeBytes: 4,
      sha256: "0".repeat(64),
    }),
  };
}
