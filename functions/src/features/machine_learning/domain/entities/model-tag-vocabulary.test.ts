import assert from "node:assert/strict";
import test from "node:test";
import {type ModelTag} from "./model-tag.js";
import {ModelTagVocabulary, UnknownModelTagError} from "./model-tag-vocabulary.js";

const animals: ModelTag = {key: "animals", labels: {en: "Animals", de: "Tiere"}, synonyms: {de: ["Tier"]}};
const pets: ModelTag = {key: "pets", parent: "animals", labels: {en: "Pets", de: "Haustiere"}, synonyms: {de: ["Hund", "Katze"]}};

test("adds the parent of a tag so a search for the topic finds the sub-tag", () => {
  const vocabulary = new ModelTagVocabulary([animals, pets]);

  assert.deepEqual(vocabulary.withAncestors(["pets"]), ["pets", "animals"]);
  assert.deepEqual(vocabulary.withAncestors(["rechnung"]), ["rechnung"]);
});

test("matches labels and synonyms in every language, ignoring case", () => {
  const vocabulary = new ModelTagVocabulary([animals, pets]);

  assert.deepEqual([...vocabulary.keysMatching("tiere")], ["animals", "pets"]);
  assert.deepEqual([...vocabulary.keysMatching("hund")], ["pets"]);
  assert.deepEqual([...vocabulary.keysMatching("pets")], ["pets"]);
});

test("resolves a label by exact locale, base language and English fallback", () => {
  const vocabulary = new ModelTagVocabulary([animals]);

  assert.equal(vocabulary.labelFor("animals", "de-AT"), "Tiere");
  assert.equal(vocabulary.labelFor("animals", "tr"), "Animals");
  assert.equal(vocabulary.labelFor("missing", "de"), undefined);
});

test("names every unknown tag and hints at a vocabulary that is not loaded yet", () => {
  assert.throws(
    () => new ModelTagVocabulary([animals]).requireKnown(["animals", "cars", "boats"]),
    (error) => error instanceof UnknownModelTagError && /cars, boats\.$/.test(error.message),
  );
  assert.throws(() => ModelTagVocabulary.empty().requireKnown(["cars"]), /noch nicht geladen/);
});

test("rejects invalid keys, missing English labels, unknown parents and a third level", () => {
  assert.throws(() => new ModelTagVocabulary([{key: "Tiere", labels: {en: "Animals"}}]), /Schlüssel/);
  assert.throws(() => new ModelTagVocabulary([{key: "animals", labels: {de: "Tiere"}}]), /englische Bezeichnung/);
  assert.throws(() => new ModelTagVocabulary([pets]), /Obertag „animals“ .* fehlt/);
  assert.throws(
    () => new ModelTagVocabulary([animals, pets, {key: "dogs", parent: "pets", labels: {en: "Dogs"}}]),
    /zwei Ebenen/,
  );
  assert.throws(() => new ModelTagVocabulary([animals, animals]), /doppelt/);
});
