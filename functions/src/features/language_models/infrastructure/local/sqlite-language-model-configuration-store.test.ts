import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {languageModelConnections, languageModels, languageModelSecrets} from "../../../../db/schema.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "./encrypted-sqlite-language-model-secret-store.js";
import {SQLiteLanguageModelConfigurationStore} from "./sqlite-language-model-configuration-store.js";

test("rolls back the connection and encrypted secret when saving a model fails", async (t) => {
  const database = await runtimeTestDatabase(t);
  const secrets = new EncryptedSQLiteLanguageModelSecretStore(database, {
    encrypt: (value) => `encrypted:${value}`, decrypt: (value) => value.slice(10),
  });
  const store = new SQLiteLanguageModelConfigurationStore(database, secrets);
  await assert.rejects(store.saveConnection({teamId: "team-1", apiKey: "secret",
    connection: {name: "Provider", provider: "openAiCompatible"},
    models: [{name: null as unknown as string, modelId: "model-1", capabilities: {
      textGeneration: true, imageInput: false, structuredOutput: false, toolCalling: false, imageGeneration: false, speechSynthesis: false,
    }}],
  }));
  assert.deepEqual(await database.select().from(languageModelConnections), []);
  assert.deepEqual(await database.select().from(languageModelSecrets), []);
  assert.deepEqual(await database.select().from(languageModels), []);
});
