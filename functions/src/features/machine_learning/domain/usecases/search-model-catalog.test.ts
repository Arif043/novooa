import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {ModelSearchCriteria} from "../entities/model-search-criteria.js";
import {type ModelTask} from "../entities/model-task.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type SystemModelCatalog} from "../repositories/system-model-catalog.js";
import {SearchModelCatalog} from "./search-model-catalog.js";

const systemEntries = [
  entry("whisper-de", "automatic-speech-recognition", ["de"], ["sprache", "transkription"]),
  entry("mobilenet", "image-classification", [], ["bild", "klassifikation"]),
  entry("sentiment-en", "text-classification", ["en"], ["stimmung"]),
];
const teamEntry = entry("team-ocr", "image-to-text", [], ["rechnung", "ocr"]);

test("searches only the global catalog without a team", async () => {
  const found = await search(new ModelSearchCriteria(null, [], "", 10), null);

  assert.deepEqual(found, ["whisper-de", "mobilenet", "sentiment-en"]);
});

test("includes team models when a team is known", async () => {
  const found = await search(new ModelSearchCriteria(null, [], "rechnung", 10), "team-1");

  assert.deepEqual(found, ["team-ocr"]);
});

test("filters by task and language, keeping language independent models", async () => {
  const byTask = await search(new ModelSearchCriteria("image-classification", ["de"], "", 10), null);
  const byLanguage = await search(new ModelSearchCriteria(null, ["de-AT"], "", 10), null);

  assert.deepEqual(byTask, ["mobilenet"]);
  assert.deepEqual(byLanguage, ["whisper-de", "mobilenet"]);
});

test("ranks by the number of matching search terms and respects the limit", async () => {
  const found = await search(new ModelSearchCriteria(null, [], "bild klassifikation stimmung", 1), null);

  assert.deepEqual(found, ["mobilenet"]);
});

test("rejects an unknown task and an invalid limit", () => {
  assert.throws(() => new ModelSearchCriteria("zaubern" as ModelTask, [], "", 5));
  assert.throws(() => new ModelSearchCriteria(null, [], "", 0));
});

async function search(criteria: ModelSearchCriteria, teamId: string | null): Promise<string[]> {
  const useCase = new SearchModelCatalog(new FakeCatalog(), new FakeSystemCatalog());
  return (await useCase.execute(criteria, teamId)).map((found) => found.id);
}

class FakeSystemCatalog implements SystemModelCatalog {
  async listSystemEntries(): Promise<readonly ModelCatalogEntry[]> {
    return systemEntries;
  }
}

class FakeCatalog implements ModelCatalog {
  async save(): Promise<void> {}

  async listAvailableFor(teamId: string): Promise<readonly ModelCatalogEntry[]> {
    return teamId === "team-1" ? [...systemEntries, teamEntry] : systemEntries;
  }

  async findAvailableFor(): Promise<ModelCatalogEntry | null> {
    return null;
  }
}

function entry(id: string, task: ModelTask, languages: string[], tags: string[]): ModelCatalogEntry {
  return {
    id, title: id, description: `Modell ${id}`, task, languages, tags,
    scope: {type: "system"},
    runtime: "onnx",
    artifactReference: {
      artifactId: `${id}-artifact`, versionId: "1", format: "onnx",
      contentType: "application/onnx", sizeBytes: 1, sha256: "a".repeat(64),
    },
    contract: {inputs: [], outputs: []},
  };
}
