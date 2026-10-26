import assert from "node:assert/strict";
import test from "node:test";
import {modelTagData, modelTagFromData, modelTagVocabularyFromFileData} from "./model-tag-vocabulary-codec.js";

test("reads the tag file into a validated vocabulary", () => {
  const vocabulary = modelTagVocabularyFromFileData({tags: [
    {key: "documents", labels: {en: "Documents", de: "Dokumente"}},
    {key: "invoices", parent: "documents", labels: {en: "Invoices"}, synonyms: {de: ["Rechnung"]}},
  ]});

  assert.deepEqual(vocabulary.withAncestors(["invoices"]), ["invoices", "documents"]);
});

test("round-trips a tag through its stored form, including a missing parent stored as null", () => {
  const tag = {key: "documents", labels: {en: "Documents"}, synonyms: {de: ["Beleg"]}};

  assert.deepEqual(modelTagFromData(tag.key, modelTagData(tag)), tag);
  assert.equal(modelTagData(tag).parent, null);
});

test("rejects a tag file without a list and tags with invalid labels or synonyms", () => {
  assert.throws(() => modelTagVocabularyFromFileData({}), /Liste „tags“/);
  assert.throws(() => modelTagFromData("animals", {labels: {en: 3}}), /Bezeichnungen/);
  assert.throws(() => modelTagFromData("animals", {labels: {en: "Animals"}, synonyms: {de: "Tier"}}), /Synonyme/);
});
