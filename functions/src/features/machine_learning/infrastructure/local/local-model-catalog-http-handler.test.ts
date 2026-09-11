import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type TeamModelCatalog} from "../../domain/repositories/model-catalog.js";
import {LocalModelArtifactPublisher} from "./local-model-artifact-publisher.js";
import {LocalModelCatalogHttpHandler} from "./local-model-catalog-http-handler.js";

test("installs a team-scoped ONNX model from a manifest and lists it", async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-import-"));
  const catalog = new Catalog();
  const handler = new LocalModelCatalogHttpHandler(
    catalog,
    new LocalModelArtifactPublisher(directory),
    "team-1",
    new Logger(),
  );

  try {
    const imported = await handler.handle({
      method: "POST",
      url: "/v1/ml-models",
      body: {manifest: manifest(), artifactBase64: Buffer.from("onnx").toString("base64")},
    });
    const listed = await handler.handle({method: "GET", url: "/v1/ml-models", body: {}});

    assert.equal(imported?.statusCode, 201);
    assert.equal(catalog.entries[0]?.scope.type, "team");
    assert.deepEqual(listed?.body, {items: catalog.entries});
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
});

test("does not remove a model owned by another team", async () => {
  const handler = new LocalModelCatalogHttpHandler(
    new Catalog(),
    new LocalModelArtifactPublisher("/tmp/novooa-unused"),
    "team-1",
    new Logger(),
  );

  const response = await handler.handle({
    method: "DELETE",
    url: "/v1/ml-models/unknown",
    body: {},
  });

  assert.equal(response?.statusCode, 404);
});

class Catalog implements TeamModelCatalog {
  entries: ModelCatalogEntry[] = [];

  async save(entry: ModelCatalogEntry): Promise<void> {
    this.entries = [...this.entries.filter((item) => item.id !== entry.id), entry];
  }

  async listAvailableFor(): Promise<readonly ModelCatalogEntry[]> {
    return this.entries;
  }

  async findAvailableFor(): Promise<ModelCatalogEntry | null> {
    return null;
  }

  async removeTeamEntry(): Promise<boolean> {
    return false;
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
        name: "input", source: "tensor", dataType: "uint8", shape: [1], preprocessing: [],
      }],
      outputs: [{
        name: "output", dataType: "uint8", shape: [1], semantic: "classification.scores", postprocessing: [],
      }],
    },
  };
}
