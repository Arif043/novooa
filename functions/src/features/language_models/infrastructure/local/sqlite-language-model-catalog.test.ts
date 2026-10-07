import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {languageModelConnections, languageModels} from "../../../../db/schema.js";
import {SQLiteLanguageModelCatalog} from "./sqlite-language-model-catalog.js";

test("loads a local model profile and its API key from the local secret store", async (t) => {
  const database = await runtimeTestDatabase(t);
  await database.insert(languageModelConnections).values({id: "connection-1", team_id: "team-1", name: "Ollama",
    provider: "openAiCompatible", base_url: "http://127.0.0.1:11434/v1", secret_ref: "language-model/connection-1"});
  await database.insert(languageModels).values({id: "model-1", connection_id: "connection-1",
    name: "Lokales Qwen", model_id: "qwen3", capabilities_json: JSON.stringify({textGeneration: true, structuredOutput: true})});
  const catalog = new SQLiteLanguageModelCatalog(database, {
    async read(secretRef) {assert.equal(secretRef, "language-model/connection-1"); return "local-key";},
    async write() {}, async delete() {},
  });
  assert.equal((await catalog.loadModel("team-1", "model-1")).modelId, "qwen3");
  assert.equal((await catalog.loadConnection("team-1", "connection-1")).baseUrl, "http://127.0.0.1:11434/v1");
  assert.equal(await catalog.loadConnectionApiKey("team-1", "connection-1"), "local-key");
  await assert.rejects(catalog.loadModel("other-team", "model-1"));
});
