import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type SystemModel, type SystemModelSource} from "../repositories/system-model-source.js";
import {CacheSystemModel, SystemModelNotFoundError} from "./cache-system-model.js";

test("keeps an already cached model without prefetching it again", async () => {
  const {cache, catalog, source} = setup();
  await catalog.save(teamEntry());

  const cached = await cache.execute("team-1", "classifier");

  assert.equal(cached.id, "classifier");
  assert.equal(source.lookups, 0);
});

test("prefetches a missing model in the ML service and stores it as cached team entry", async () => {
  const {cache, catalog, prefetched} = setup();

  const cached = await cache.execute("team-1", "classifier");

  assert.deepEqual(cached.scope, {type: "team", teamId: "team-1"});
  assert.equal(cached.origin, "catalog");
  assert.equal(catalog.entries.length, 1);
  assert.deepEqual(prefetched.map((entry) => entry.id), ["classifier"]);
});

test("a failed prefetch stores nothing", async () => {
  const catalog = new Catalog();
  const failing = {prefetch: () => Promise.reject(new Error("Speicher nicht erreichbar."))};
  const cache = new CacheSystemModel(catalog, new Source(), {validate: async () => undefined}, failing);

  await assert.rejects(cache.execute("team-1", "classifier"), /Speicher nicht erreichbar/);
  assert.equal(catalog.entries.length, 0);
});

test("parallel requests for the same model share one prefetch", async () => {
  const {cache, prefetched} = setup();

  await Promise.all([cache.execute("team-1", "classifier"), cache.execute("team-1", "classifier")]);

  assert.equal(prefetched.length, 1);
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
  const prefetched: ModelCatalogEntry[] = [];
  const prefetcher = {prefetch: async (entry: ModelCatalogEntry) => {
    await new Promise((resolve) => setTimeout(resolve, 1));
    prefetched.push(entry);
  }};
  return {cache: new CacheSystemModel(catalog, source, contract, prefetcher), catalog, source, contract, prefetched};
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
  lookups = 0;

  async find(modelId: string): Promise<SystemModel | null> {
    this.lookups += 1;
    return modelId === "classifier" ? {entry: systemEntry()} : null;
  }
}

function teamEntry(): ModelCatalogEntry {
  return {...systemEntry(), scope: {type: "team", teamId: "team-1"}, origin: "catalog"};
}

function systemEntry(): ModelCatalogEntry {
  return {
    id: "classifier", title: "Classifier", description: "Testmodell", task: "image-classification", languages: [], tags: ["test"],
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
