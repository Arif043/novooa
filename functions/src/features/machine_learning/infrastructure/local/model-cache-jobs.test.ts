import assert from "node:assert/strict";
import test from "node:test";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type CacheSystemModel, SystemModelNotFoundError} from "../../domain/usecases/cache-system-model.js";
import {ModelCacheJobs} from "./model-cache-jobs.js";
import {SelfCachingModelCatalog} from "./self-caching-model-catalog.js";

test("reports a running download and clears it when the model is cached", async () => {
  const cache = new ControlledCache();
  const topics: string[] = [];
  const jobs = new ModelCacheJobs("team-1", cache.asUseCase(), {publish: (topic) => topics.push(topic)}, silent);

  jobs.start("classifier");
  jobs.start("classifier");
  assert.deepEqual(jobs.list(), [{modelId: "classifier", state: "downloading"}]);
  cache.resolve();
  await settle();

  assert.equal(cache.calls, 1);
  assert.deepEqual(jobs.list(), []);
  assert.deepEqual(topics, ["model-cache", "model-cache", "model-catalog"]);
});

test("keeps a failed download with a readable message and allows a retry", async () => {
  const cache = new ControlledCache();
  const jobs = new ModelCacheJobs("team-1", cache.asUseCase(), {publish: () => undefined}, silent);

  jobs.start("classifier");
  cache.reject(new Error("socket hang up"));
  await settle();
  assert.deepEqual(jobs.list(), [{
    modelId: "classifier", state: "failed",
    message: "Das Modell konnte nicht heruntergeladen werden. Bitte versuche es erneut.",
  }]);
  jobs.start("classifier");

  assert.equal(cache.calls, 2);
  assert.equal(jobs.list()[0]?.state, "downloading");
});

test("the inference catalog loads a missing model before the run", async () => {
  const cache = new ControlledCache();
  const catalog = new SelfCachingModelCatalog(emptyCatalog, cache.asUseCase());

  const pending = catalog.findAvailableFor("team-1", "classifier");
  await settle();
  cache.resolve();

  assert.equal((await pending)?.id, "classifier");
});

test("the inference catalog reports an unknown model as unavailable", async () => {
  const cache = new ControlledCache();
  const catalog = new SelfCachingModelCatalog(emptyCatalog, cache.asUseCase());

  const pending = catalog.findAvailableFor("team-1", "unknown");
  await settle();
  cache.reject(new SystemModelNotFoundError("unknown"));

  assert.equal(await pending, null);
});

class ControlledCache {
  calls = 0;
  private settle: {resolve(entry: ModelCatalogEntry): void; reject(error: Error): void} | undefined;

  asUseCase(): CacheSystemModel {
    return {execute: () => {
      this.calls += 1;
      return new Promise<ModelCatalogEntry>((resolve, reject) => { this.settle = {resolve, reject}; });
    }} as unknown as CacheSystemModel;
  }

  resolve(): void { this.settle?.resolve({id: "classifier"} as ModelCatalogEntry); }
  reject(error: Error): void { this.settle?.reject(error); }
}

const emptyCatalog = {
  save: async () => undefined,
  listAvailableFor: async () => [],
  findAvailableFor: async () => null,
};

const silent: ApplicationLogger = {
  info: () => undefined, error: () => undefined, exception: () => undefined,
  readableInfo: () => undefined, readableError: () => undefined,
};

async function settle(): Promise<void> {
  await new Promise((resolve) => setImmediate(resolve));
}
