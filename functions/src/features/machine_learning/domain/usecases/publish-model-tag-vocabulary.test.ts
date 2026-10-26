import assert from "node:assert/strict";
import test from "node:test";
import {ModelTagVocabulary} from "../entities/model-tag-vocabulary.js";
import {PublishModelTagVocabulary} from "./publish-model-tag-vocabulary.js";

const vocabulary = new ModelTagVocabulary([{key: "documents", labels: {en: "Documents"}}]);

test("publishes the maintained vocabulary", async () => {
  const saved: ModelTagVocabulary[] = [];
  const published = await new PublishModelTagVocabulary({load: async () => vocabulary}, {save: async (value) => void saved.push(value)})
    .execute({dryRun: false});

  assert.equal(published, vocabulary);
  assert.deepEqual(saved, [vocabulary]);
});

test("only reads and validates during a dry run", async () => {
  const saved: ModelTagVocabulary[] = [];
  await new PublishModelTagVocabulary({load: async () => vocabulary}, {save: async (value) => void saved.push(value)})
    .execute({dryRun: true});

  assert.deepEqual(saved, []);
});
