import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {ModelTagVocabulary} from "../../domain/entities/model-tag-vocabulary.js";
import {CachedModelTagVocabulary} from "./cached-model-tag-vocabulary.js";
import {SQLiteModelTagVocabulary} from "./sqlite-model-tag-vocabulary.js";

const global = new ModelTagVocabulary([
  {key: "animals", labels: {en: "Animals", de: "Tiere"}},
  {key: "pets", parent: "animals", labels: {en: "Pets"}, synonyms: {de: ["Hund"]}},
]);

test("mirrors the global vocabulary and keeps parents and synonyms", async (t) => {
  const mirror = new SQLiteModelTagVocabulary(await runtimeTestDatabase(t));

  await new CachedModelTagVocabulary({load: async () => global}, mirror).load();
  const stored = await mirror.load();

  assert.deepEqual(stored.withAncestors(["pets"]), ["pets", "animals"]);
  assert.deepEqual([...stored.keysMatching("hund")], ["pets"]);
});

test("serves the last mirror when the global catalog cannot be read", async (t) => {
  const mirror = new SQLiteModelTagVocabulary(await runtimeTestDatabase(t));
  await mirror.replaceAll(global);
  const failures: unknown[] = [];
  const failing = {load: async (): Promise<ModelTagVocabulary> => {
    throw new Error("offline");
  }};

  const vocabulary = await new CachedModelTagVocabulary(failing, mirror, (error) => failures.push(error)).load();

  assert.equal(vocabulary.labelFor("animals", "de"), "Tiere");
  assert.equal(failures.length, 1);
});

test("serves the mirror without a Firebase session and replaces it as a whole", async (t) => {
  const mirror = new SQLiteModelTagVocabulary(await runtimeTestDatabase(t));
  await mirror.replaceAll(global);
  await mirror.replaceAll(new ModelTagVocabulary([{key: "documents", labels: {en: "Documents"}}]));

  const vocabulary = await new CachedModelTagVocabulary(undefined, mirror).load();

  assert.deepEqual(vocabulary.tags.map((tag) => tag.key), ["documents"]);
});
