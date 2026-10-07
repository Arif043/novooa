import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {randomBytes} from "node:crypto";
import test from "node:test";
import {connectRuntimeDatabase, RuntimeDatabase} from "../../../../db/database.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "./encrypted-sqlite-language-model-secret-store.js";
import {LocalLanguageModelDiscovery, type DiscoveredLanguageModel} from "./local-language-model-discovery.js";
import {languageModelRoutes} from "./local-language-model-routes.js";
import {SQLiteLanguageModelConfigurationStore} from "./sqlite-language-model-configuration-store.js";

test("stores a local model configuration without exposing its API key", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createTables(database);
  const secretStore = new EncryptedSQLiteLanguageModelSecretStore(
    database,
    new CredentialCipher(randomBytes(32).toString("base64")),
  );
  const handler = testingRoutes(languageModelRoutes, {store: new SQLiteLanguageModelConfigurationStore(database, secretStore), notifier: new LocalRuntimeRealtimeNotifier()});

  const saved = await handler.handle({body: requestBody(), method: "POST", url: "/v1/language-models"});
  const listed = await handler.handle({body: {}, method: "GET", url: "/v1/language-models"});

  assert.equal(saved?.statusCode, 201);
  assert.equal((saved?.body as {apiKey?: unknown}).apiKey, undefined);
  assert.deepEqual((listed?.body as {items: Array<{modelId: string}>}).items, [
    {id: (saved?.body as {id: string}).id, teamId: "team-1", connectionId: (saved?.body as {connectionId: string}).connectionId,
      name: "Mein Modell", modelId: "gpt-4.1-mini", capabilities: {
        textGeneration: true, imageInput: false, structuredOutput: true,
        toolCalling: false, imageGeneration: false,
      }},
  ]);
  database.$client.close();
});

test("uses an internal credential for a keyless local endpoint", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createTables(database);
  const secretStore = new EncryptedSQLiteLanguageModelSecretStore(
    database,
    new CredentialCipher(randomBytes(32).toString("base64")),
  );
  const handler = testingRoutes(languageModelRoutes, {store: new SQLiteLanguageModelConfigurationStore(database, secretStore), notifier: new LocalRuntimeRealtimeNotifier()});

  const response = await handler.handle({
    body: {...requestBody(), baseUrl: "http://host.docker.internal:11434/v1", apiKey: ""},
    method: "POST",
    url: "/v1/language-models",
  });
  const secretRef = await database.get <{secret_ref: string}>(sql`SELECT secret_ref FROM language_model_connections`);

  assert.equal(response?.statusCode, 201);
  assert.equal(await secretStore.read(secretRef?.secret_ref ?? ""), "local");
  database.$client.close();
});

test("connects all models discovered for one provider connection", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createTables(database);
  const handler = testingRoutes(languageModelRoutes, {store: new SQLiteLanguageModelConfigurationStore(database, new EncryptedSQLiteLanguageModelSecretStore(
      database, new CredentialCipher(randomBytes(32).toString("base64")),
    )), notifier: new LocalRuntimeRealtimeNotifier(), discovery: {discover: async () => discoveredModels()}});

  const response = await handler.handle({
    body: {provider: "googleAi", apiKey: "provider-api-key"},
    method: "POST",
    url: "/v1/language-model-connections",
  });

  assert.equal(response?.statusCode, 201);
  assert.deepEqual((response?.body as {items: Array<{modelId: string}>}).items.map((model) => model.modelId), ["gemini-2.5-flash", "gemini-2.5-pro"]);
  database.$client.close();
});

test("connects Ollama with its local default endpoint and no API key", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createTables(database);
  const secrets = new EncryptedSQLiteLanguageModelSecretStore(
    database, new CredentialCipher(randomBytes(32).toString("base64")),
  );
  const handler = testingRoutes(languageModelRoutes, {store: new SQLiteLanguageModelConfigurationStore(database, secrets), notifier: new LocalRuntimeRealtimeNotifier(), discovery: {discover: async () => discoveredModels()}});

  const response = await handler.handle({
    body: {provider: "ollama"},
    method: "POST",
    url: "/v1/language-model-connections",
  });
  const connection = await database.get <{provider: string; base_url: string; secret_ref: string}>(sql`SELECT provider, base_url, secret_ref FROM language_model_connections`);

  assert.equal(response?.statusCode, 201);
  assert.equal(connection?.provider, "ollama");
  assert.equal(connection?.base_url, "http://host.docker.internal:11434/v1");
  assert.equal(await secrets.read(connection?.secret_ref ?? ""), "local");
  database.$client.close();
});

test("reads model names from Ollama's native tags response", async () => {
  const discovery = new LocalLanguageModelDiscovery(async () => new Response(JSON.stringify({
    models: [{name: "gemma4:e2b", model: "gemma4:e2b"}],
  })));
  const models = await discovery.discover({
    provider: "ollama",
    baseUrl: "http://host.docker.internal:11434/v1",
    apiKey: "local",
  });

  assert.deepEqual(models.map((model) => model.modelId), ["gemma4:e2b"]);
});

test("lists connected providers", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createTables(database);
  const handler = testingRoutes(languageModelRoutes, {store: new SQLiteLanguageModelConfigurationStore(database, new EncryptedSQLiteLanguageModelSecretStore(
      database, new CredentialCipher(randomBytes(32).toString("base64")),
    )), notifier: new LocalRuntimeRealtimeNotifier(), discovery: {discover: async () => discoveredModels()}});
  await handler.handle({
    body: {provider: "googleAi", apiKey: "provider-api-key"},
    method: "POST",
    url: "/v1/language-model-connections",
  });

  const response = await handler.handle({body: {}, method: "GET", url: "/v1/language-model-connections"});

  assert.equal(response?.statusCode, 200);
  assert.deepEqual(
    (response?.body as {items: Array<{name: string; provider: string}>}).items.map(
      (connection) => ({name: connection.name, provider: connection.provider}),
    ),
    [{name: "Google AI", provider: "googleAi"}],
  );
  database.$client.close();
});

test("removes a connection together with its models and their secret", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createTables(database);
  const secrets = new EncryptedSQLiteLanguageModelSecretStore(
    database, new CredentialCipher(randomBytes(32).toString("base64")),
  );
  const notifier = new LocalRuntimeRealtimeNotifier();
  const events: string[] = [];
  notifier.subscribe("language-models", {send: () => events.push("language-models")});
  const handler = testingRoutes(languageModelRoutes, {store: new SQLiteLanguageModelConfigurationStore(database, secrets), notifier: notifier, discovery: {discover: async () => discoveredModels()}});
  const connected = await handler.handle({
    body: {provider: "googleAi", apiKey: "provider-api-key"},
    method: "POST",
    url: "/v1/language-model-connections",
  });
  const connectionId = (connected?.body as {items: Array<{connectionId: string}>}).items[0].connectionId;
  const secretRef = (await database.get <{secret_ref: string}>(sql`SELECT secret_ref FROM language_model_connections WHERE id = ${connectionId}`))?.secret_ref ?? "";

  const response = await handler.handle({
    body: {}, method: "DELETE", url: `/v1/language-model-connections/${connectionId}`,
  });
  const remainingConnections = await database.all(sql`SELECT id FROM language_model_connections`);
  const remainingModels = await database.all(sql`SELECT id FROM language_models`);

  assert.equal(response?.statusCode, 200);
  assert.deepEqual(remainingConnections, []);
  assert.deepEqual(remainingModels, []);
  assert.equal(await secrets.read(secretRef), null);
  assert.ok(events.includes("language-models"));
  database.$client.close();
});

function discoveredModels(): DiscoveredLanguageModel[] {
  const capabilities = {textGeneration: true, imageInput: false, structuredOutput: true, toolCalling: false, imageGeneration: false};
  return [
    {modelId: "gemini-2.5-flash", name: "Gemini 2.5 Flash", capabilities},
    {modelId: "gemini-2.5-pro", name: "Gemini 2.5 Pro", capabilities},
  ];
}

function requestBody() {
  return {
    connectionName: "OpenAI", provider: "openAiCompatible",
    baseUrl: "https://api.openai.com/v1", name: "Mein Modell",
    languageModelId: "gpt-4.1-mini", apiKey: "provider-api-key",
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

for (const [provider, displayName, baseUrl] of [
  ["abacus", "Abacus.AI (RouteLLM)", "https://routellm.abacus.ai/v1"],
  ["huggingFace", "Hugging Face", "https://router.huggingface.co/v1"],
] as const) {
  test(`connects ${provider} as its own provider with a fixed endpoint`, async () => {
    const database = connectRuntimeDatabase(":memory:");
    await createTables(database);
    const handler = testingRoutes(languageModelRoutes, {
      store: new SQLiteLanguageModelConfigurationStore(database, new EncryptedSQLiteLanguageModelSecretStore(
        database, new CredentialCipher(randomBytes(32).toString("base64")),
      )),
      notifier: new LocalRuntimeRealtimeNotifier(),
      discovery: {discover: async () => discoveredModels()},
    });

    const created = await handler.handle({
      body: {provider, apiKey: "provider-api-key"}, method: "POST", url: "/v1/language-model-connections",
    });
    const connections = await handler.handle({body: {}, method: "GET", url: "/v1/language-model-connections"});

    assert.equal(created?.statusCode, 201);
    assert.deepEqual(
      (connections?.body as {items: Array<{name: string; provider: string; baseUrl: string}>}).items
        .map(({name, provider: stored, baseUrl: url}) => ({name, provider: stored, baseUrl: url})),
      [{name: displayName, provider, baseUrl}],
    );
    database.$client.close();
  });

  test(`rejects another API address for ${provider}`, async () => {
    const database = connectRuntimeDatabase(":memory:");
    await createTables(database);
    const handler = testingRoutes(languageModelRoutes, {
      store: new SQLiteLanguageModelConfigurationStore(database, new EncryptedSQLiteLanguageModelSecretStore(
        database, new CredentialCipher(randomBytes(32).toString("base64")),
      )),
      notifier: new LocalRuntimeRealtimeNotifier(),
      discovery: {discover: async () => discoveredModels()},
    });

    const response = await handler.handle({
      body: {provider, apiKey: "provider-api-key", baseUrl: "https://evil.example/v1"},
      method: "POST", url: "/v1/language-model-connections",
    });

    assert.equal(response?.statusCode, 400);
    database.$client.close();
  });
}

test("discovery asks the fixed Abacus and Hugging Face endpoints with the API key", async () => {
  const requests: Array<{url: string; authorization: string | undefined}> = [];
  const discovery = new LocalLanguageModelDiscovery((async (url: URL, init?: {headers?: Record<string, string>}) => {
    requests.push({url: String(url), authorization: init?.headers?.Authorization});
    return new Response(JSON.stringify({data: [{id: "org/model"}]}), {status: 200});
  }) as typeof fetch);

  await discovery.discover({provider: "abacus", apiKey: "abacus-key"});
  await discovery.discover({provider: "huggingFace", apiKey: "hf-key"});

  assert.deepEqual(requests, [
    {url: "https://routellm.abacus.ai/v1/models", authorization: "Bearer abacus-key"},
    {url: "https://router.huggingface.co/v1/models", authorization: "Bearer hf-key"},
  ]);
});

test("connects ElevenLabs through its own SDK discovery", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createTables(database);
  const requestedKeys: string[] = [];
  const discovery = new LocalLanguageModelDiscovery(fetch, (apiKey) => {
    requestedKeys.push(apiKey);
    return {
      listSpeechModels: async () => [{modelId: "eleven_multilingual_v2", name: "Eleven Multilingual v2"}],
      listVoices: async () => [],
      synthesize: async () => new Uint8Array(), transcribe: async () => "",
    };
  });
  const handler = testingRoutes(languageModelRoutes, {
    store: new SQLiteLanguageModelConfigurationStore(database, new EncryptedSQLiteLanguageModelSecretStore(
      database, new CredentialCipher(randomBytes(32).toString("base64")),
    )),
    notifier: new LocalRuntimeRealtimeNotifier(),
    discovery,
  });

  const created = await handler.handle({
    body: {provider: "elevenLabs", apiKey: "eleven-api-key"}, method: "POST", url: "/v1/language-model-connections",
  });
  const connections = await handler.handle({body: {}, method: "GET", url: "/v1/language-model-connections"});
  const models = await handler.handle({body: {}, method: "GET", url: "/v1/language-models"});

  assert.equal(created?.statusCode, 201);
  assert.deepEqual(requestedKeys, ["eleven-api-key"]);
  assert.deepEqual(
    (connections?.body as {items: Array<{name: string; provider: string; baseUrl?: string}>}).items
      .map(({name, provider, baseUrl}) => ({name, provider, baseUrl})),
    [{name: "ElevenLabs", provider: "elevenLabs", baseUrl: undefined}],
  );
  const stored = (models?.body as {items: Array<{modelId: string; capabilities: Record<string, boolean>}>}).items;
  assert.equal(stored[0].modelId, "eleven_multilingual_v2");
  database.$client.close();
});

test("ignores a custom API address for ElevenLabs instead of storing it", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createTables(database);
  const handler = testingRoutes(languageModelRoutes, {
    store: new SQLiteLanguageModelConfigurationStore(database, new EncryptedSQLiteLanguageModelSecretStore(
      database, new CredentialCipher(randomBytes(32).toString("base64")),
    )),
    notifier: new LocalRuntimeRealtimeNotifier(),
    discovery: {discover: async () => discoveredModels()},
  });

  const response = await handler.handle({
    body: {provider: "elevenLabs", apiKey: "eleven-api-key", baseUrl: "https://evil.example/v1"},
    method: "POST", url: "/v1/language-model-connections",
  });
  const connections = await handler.handle({body: {}, method: "GET", url: "/v1/language-model-connections"});

  assert.equal(response?.statusCode, 201);
  assert.equal((connections?.body as {items: Array<{baseUrl?: string}>}).items[0].baseUrl, undefined);
  database.$client.close();
});

test("discovery lists Google text-to-speech models even without generateContent", async () => {
  const discovery = new LocalLanguageModelDiscovery((async () => new Response(JSON.stringify({models: [
    {name: "models/gemini-3.8-flash-tts", displayName: "Gemini 3.8 Flash TTS", supportedGenerationMethods: ["createInteraction"]},
    {name: "models/embedding-001", displayName: "Embedding", supportedGenerationMethods: ["embedContent"]},
  ]}), {status: 200})));

  const google = await discovery.discover({provider: "googleAi", apiKey: "key"});

  assert.deepEqual(google.map((model) => model.modelId), ["gemini-3.8-flash-tts"]);
});
