import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {languageModelConnections, languageModels, languageModelSecrets, teams} from "../../../../db/schema.js";
import {defaultLanguageModelCapabilities} from "../../domain/entities/language-model.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "./encrypted-sqlite-language-model-secret-store.js";
import {SQLiteLanguageModelCatalog} from "./sqlite-language-model-catalog.js";
import {SQLiteLanguageModelConfigurationStore} from "./sqlite-language-model-configuration-store.js";
import {type TransactionalLanguageModelSecretStore} from "./local-language-model-secret-store.js";

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Andere", owner_uid: "user-2"});
  const secrets = new EncryptedSQLiteLanguageModelSecretStore(database, {
    encrypt: (value) => `encrypted:${value}`, decrypt: (value) => value.slice(10),
  });
  return {database, secrets, store: new SQLiteLanguageModelConfigurationStore(database, secrets),
    catalog: new SQLiteLanguageModelCatalog(database, secrets)};
}

function save(store: SQLiteLanguageModelConfigurationStore, teamId: string, names = ["Modell"]) {
  return store.saveConnection({teamId, apiKey: "secret", connection: {name: "Provider", provider: "openAiCompatible"},
    models: names.map((name) => ({name, modelId: name, capabilities: defaultLanguageModelCapabilities}))});
}

test("model lists and catalog reads derive the team from the connection", async (t) => {
  const {store, catalog} = await fixture(t);
  const models = await save(store, "team-1", ["Zeta", "Alpha"]);
  const [other] = await save(store, "team-2");
  assert.deepEqual((await store.list("team-1")).map((model) => model.name), ["Alpha", "Zeta"]);
  assert.deepEqual((await store.list("team-2")).map((model) => model.id), [other.id]);
  const loaded = await catalog.loadModel("team-1", models[0].id);
  assert.equal(loaded.teamId, "team-1");
  assert.deepEqual(loaded.capabilities, defaultLanguageModelCapabilities);
  await assert.rejects(catalog.loadModel("team-2", models[0].id), /nicht gefunden/);
  await assert.rejects(catalog.loadConnectionApiKey("team-2", models[0].connectionId), /nicht gefunden/);
});

test("deleting a connection atomically removes its models and secret while preserving other teams", async (t) => {
  const {database, store} = await fixture(t);
  const [model] = await save(store, "team-1", ["Alpha", "Beta"]);
  const [other] = await save(store, "team-2");
  await store.deleteConnection("team-2", model.connectionId);
  assert.equal((await store.list("team-1")).length, 2);
  await store.deleteConnection("team-1", model.connectionId);
  assert.deepEqual(await store.list("team-1"), []);
  assert.equal((await database.select().from(languageModelConnections)).length, 1);
  assert.equal((await database.select().from(languageModelSecrets)).length, 1);
  assert.deepEqual((await store.list("team-2")).map((entry) => entry.id), [other.id]);
});

function failingDeletion(secrets: EncryptedSQLiteLanguageModelSecretStore): TransactionalLanguageModelSecretStore {
  return {
    read: (ref) => secrets.read(ref), write: (ref, value) => secrets.write(ref, value), delete: (ref) => secrets.delete(ref),
    withDatabase: (database) => {
      const scoped = secrets.withDatabase(database);
      return {read: (ref) => scoped.read(ref), write: (ref, value) => scoped.write(ref, value),
        delete: async () => {throw new Error("Secret-Löschung fehlgeschlagen");}};
    },
  };
}

test("a failed secret deletion rolls back connection and model deletion", async (t) => {
  const {database, store, secrets} = await fixture(t);
  const [model] = await save(store, "team-1");
  const failing = new SQLiteLanguageModelConfigurationStore(database, failingDeletion(secrets));
  await assert.rejects(failing.deleteConnection("team-1", model.connectionId), /Secret-Löschung fehlgeschlagen/);
  assert.equal((await store.list("team-1"))[0].id, model.id);
  assert.equal((await store.listConnections("team-1"))[0].id, model.connectionId);
  assert.equal((await database.select().from(languageModelSecrets)).length, 1);
});

test("models require an existing connection and are removed by its foreign-key cascade", async (t) => {
  const {database, store} = await fixture(t);
  await assert.rejects(database.insert(languageModels).values({id: "orphan", connection_id: "missing",
    name: "Modell", model_id: "model"}));
  const [model] = await save(store, "team-1");
  await database.delete(languageModelConnections).where(eq(languageModelConnections.id, model.connectionId));
  assert.deepEqual(await database.select().from(languageModels), []);
  const columns = await database.all<{name: string}>(sql`PRAGMA table_info(language_models)`);
  assert.ok(!columns.some((column) => column.name === "team_id"));
  assert.ok(columns.some((column) => column.name === "capabilities_json"));
});
