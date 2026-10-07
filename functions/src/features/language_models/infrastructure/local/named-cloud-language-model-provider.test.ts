import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {randomBytes} from "node:crypto";
import test from "node:test";
import {connectRuntimeDatabase, RuntimeDatabase} from "../../../../db/database.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "./encrypted-sqlite-language-model-secret-store.js";
import {LocalLanguageModelDiscovery} from "./local-language-model-discovery.js";
import {languageModelRoutes} from "./local-language-model-routes.js";
import {SQLiteLanguageModelConfigurationStore} from "./sqlite-language-model-configuration-store.js";

test("connects Mistral with its fixed endpoint and the customer API key", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createTables(database);
  const secrets = new EncryptedSQLiteLanguageModelSecretStore(
    database, new CredentialCipher(randomBytes(32).toString("base64")),
  );
  const handler = testingRoutes(languageModelRoutes, {store: new SQLiteLanguageModelConfigurationStore(database, secrets), notifier: new LocalRuntimeRealtimeNotifier(), discovery: {discover: async () => [discoveredModel()]}});

  const response = await handler.handle({
    body: {provider: "mistral", apiKey: "customer-api-key"},
    method: "POST",
    url: "/v1/language-model-connections",
  });
  const connection = await database.get <{
    base_url: string;
    name: string;
    secret_ref: string;
  }>(sql`SELECT name, base_url, secret_ref FROM language_model_connections`);

  assert.equal(response?.statusCode, 201);
  assert.equal(connection?.name, "Mistral AI");
  assert.equal(connection?.base_url, "https://api.mistral.ai/v1");
  assert.equal(await secrets.read(connection?.secret_ref ?? ""), "customer-api-key");
  database.$client.close();
});

test("discovers xAI models through its fixed OpenAI-compatible endpoint", async () => {
  let requestedUrl = "";
  let authorization = "";
  const discovery = new LocalLanguageModelDiscovery(async (url, init) => {
    requestedUrl = url instanceof Request ? url.url : String(url);
    authorization = new Headers(init?.headers).get("Authorization") ?? "";
    return new Response(JSON.stringify({data: [{id: "grok-4", name: "Grok 4"}]}));
  });

  const models = await discovery.discover({
    provider: "xAi",
    apiKey: "customer-api-key",
  });

  assert.equal(requestedUrl, "https://api.x.ai/v1/models");
  assert.equal(authorization, "Bearer customer-api-key");
  assert.deepEqual(models.map((model) => model.modelId), ["grok-4"]);
});

function discoveredModel() {
  return {
    modelId: "mistral-small-latest",
    name: "Mistral Small",
    capabilities: {
      textGeneration: true,
      imageInput: false,
      structuredOutput: true,
      toolCalling: false,
      imageGeneration: false,
    },
  };
}

async function createTables(database: RuntimeDatabase): Promise<void> {
  await database.run(sql`PRAGMA foreign_keys = ON`);
  await database.run(sql`CREATE TABLE language_model_connections (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, name TEXT NOT NULL,
    provider TEXT NOT NULL, base_url TEXT, secret_ref TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )`);
  await database.run(sql`CREATE TABLE language_models (
    id TEXT PRIMARY KEY, connection_id TEXT NOT NULL,
    name TEXT NOT NULL, model_id TEXT NOT NULL, capabilities_json TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (connection_id) REFERENCES language_model_connections(id) ON DELETE CASCADE
  )`);
  await database.run(sql`CREATE TABLE language_model_secrets (
    secret_ref TEXT PRIMARY KEY, encrypted_value TEXT NOT NULL, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )`);
}
