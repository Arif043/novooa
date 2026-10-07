import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelArtifactPublication} from "../repositories/model-artifact-publisher.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type SystemModel, type SystemModelSource} from "../repositories/system-model-source.js";
import {CacheSystemModel, SystemModelNotFoundError} from "./cache-system-model.js";
import {InstallTeamModel} from "./install-team-model.js";

test("keeps an already cached model without downloading it again", async () => {
  const {cache, catalog, source} = setup();
  await catalog.save(teamEntry());

  const cached = await cache.execute("team-1", "classifier");

  assert.equal(cached.id, "classifier");
  assert.equal(source.downloads, 0);
});

test("downloads a missing model and stores it as cached team entry", async () => {
  const {cache, catalog, published} = setup();

  const cached = await cache.execute("team-1", "classifier");

  assert.deepEqual(cached.scope, {type: "team", teamId: "team-1"});
  assert.equal(cached.origin, "catalog");
  assert.equal(catalog.entries.length, 1);
  assert.equal(published.length, 1);
});

test("parallel requests for the same model share one download", async () => {
  const {cache, source} = setup();

  await Promise.all([cache.execute("team-1", "classifier"), cache.execute("team-1", "classifier")]);

  assert.equal(source.downloads, 1);
});

test("an unknown model fails with a not-found error", async () => {
  const {cache} = setup();

  await assert.rejects(cache.execute("team-1", "unknown"), SystemModelNotFoundError);
});

test("a rejected contract stores nothing and allows a retry", async () => {
  const {cache, catalog, contract} = setup();
  contract.reject = true;

  await assert.rejects(cache.execute("team-1", "classifier"));
  contract.reject = false;
  await cache.execute("team-1", "classifier");

  assert.equal(catalog.entries.length, 1);
});

function setup() {
  const catalog = new Catalog();
  const source = new Source();
  const contract = {reject: false, async validate() { if (this.reject) throw new Error("Vertrag ungültig."); }};
  const published: ModelArtifactPublication[] = [];
  const installer = new InstallTeamModel({publish: async (value) => { published.push(value); }}, catalog);
  return {cache: new CacheSystemModel(catalog, source, contract, installer), catalog, source, contract, published};
}

class Catalog implements ModelCatalog {
  entries: ModelCatalogEntry[] = [];
  async save(entry: ModelCatalogEntry): Promise<void> { this.entries.push(entry); }
  async listAvailableFor(): Promise<readonly ModelCatalogEntry[]> { return this.entries; }
  async findAvailableFor(_teamId: string, modelId: string): Promise<ModelCatalogEntry | null> {
    return this.entries.find((entry) => entry.id === modelId) ?? null;
  }
}

class Source implements SystemModelSource {
  downloads = 0;

  async find(modelId: string): Promise<SystemModel | null> {
    if (modelId !== "classifier") return null;
    const entry = systemEntry();
    return {entry, fetchArtifact: async () => {
      this.downloads += 1;
      await new Promise((resolve) => setTimeout(resolve, 1));
      return {reference: entry.artifactReference, content: bytes()};
    }};
  }
}

function teamEntry(): ModelCatalogEntry {
  return {...systemEntry(), scope: {type: "team", teamId: "team-1"}, origin: "catalog"};
}

function systemEntry(): ModelCatalogEntry {
  return {
    id: "classifier", title: "Classifier", description: "Testmodell", tags: ["test"],
    scope: {type: "system"}, runtime: "onnx",
    artifactReference: {
      artifactId: "classifier", versionId: "1", format: "onnx", contentType: "application/onnx",
      sizeBytes: 1, sha256: "0".repeat(64),
    },
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: []}],
      outputs: [{name: "output", semantic: "classification.scores", dataType: "uint8", shape: [1], transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}

async function* bytes(): AsyncGenerator<Uint8Array> {
  yield Uint8Array.from([1]);
}
