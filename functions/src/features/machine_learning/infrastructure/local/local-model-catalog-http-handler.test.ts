import assert from "node:assert/strict";
import {mkdtemp, readFile, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type TeamModelCatalog} from "../../domain/repositories/model-catalog.js";
import {LocalModelArtifactPublisher} from "./local-model-artifact-publisher.js";
import {LocalModelArtifactUploadStore} from "./local-model-artifact-upload-store.js";
import {LocalModelCatalogHttpHandler} from "./local-model-catalog-http-handler.js";
import {type ModelContractValidator} from "./python-model-contract-validator.js";

test("installs a team-scoped ONNX model from a manifest and lists it", async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-import-"));
  const catalog = new Catalog();
  const handler = new LocalModelCatalogHttpHandler(
    catalog,
    new LocalModelArtifactPublisher(directory),
    new LocalModelArtifactUploadStore(directory),
    "team-1",
    new Validator(),
    new Logger(),
    new LocalRuntimeRealtimeNotifier(),
  );

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

test("rejects a manifest whose transformation is not supported by the Python runtime", async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-import-"));
  const handler = new LocalModelCatalogHttpHandler(
    new Catalog(),
    new LocalModelArtifactPublisher(directory),
    new LocalModelArtifactUploadStore(directory),
    "team-1",
    new RejectingValidator(),
    new Logger(),
    new LocalRuntimeRealtimeNotifier(),
  );

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
  const handler = new LocalModelCatalogHttpHandler(
    new Catalog(),
    new LocalModelArtifactPublisher("/tmp/novooa-unused"),
    new LocalModelArtifactUploadStore("/tmp/novooa-unused"),
    "team-1",
    new Validator(),
    new Logger(),
    new LocalRuntimeRealtimeNotifier(),
  );

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
  const handler = new LocalModelCatalogHttpHandler(
    catalog,
    new LocalModelArtifactPublisher(directory),
    new LocalModelArtifactUploadStore(directory),
    "team-1",
    new Validator(),
    new Logger(),
    new LocalRuntimeRealtimeNotifier(),
  );

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
  const handler = new LocalModelCatalogHttpHandler(
    catalog,
    new LocalModelArtifactPublisher(directory),
    new LocalModelArtifactUploadStore(directory),
    "team-1",
    new Validator(),
    new Logger(),
    new LocalRuntimeRealtimeNotifier(),
  );
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
  handler: LocalModelCatalogHttpHandler,
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
