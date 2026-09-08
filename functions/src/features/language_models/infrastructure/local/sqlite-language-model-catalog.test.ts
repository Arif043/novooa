import assert from "node:assert/strict";
import test from "node:test";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {SQLiteLanguageModelCatalog} from "./sqlite-language-model-catalog.js";

test("loads a local model profile and its API key from the local secret store", async () => {
  const catalog = new SQLiteLanguageModelCatalog(
    databaseWith([
      {
        id: "model-1",
        connection_id: "connection-1",
        name: "Lokales Qwen",
        model_id: "qwen3",
        capabilities_json: JSON.stringify({
          textGeneration: true,
          imageInput: false,
          structuredOutput: true,
          toolCalling: false,
          imageGeneration: false,
        }),
      },
      {
        id: "connection-1",
        name: "Ollama",
        provider: "openAiCompatible",
        base_url: "http://127.0.0.1:11434/v1",
        secret_ref: "language-model/connection-1",
      },
    ]),
    {async read(secretRef) {
      assert.equal(secretRef, "language-model/connection-1");
      return "local-key";
    }},
  );

  const model = await catalog.loadModel("team-1", "model-1");
  const connection = await catalog.loadConnection("team-1", "connection-1");
  const apiKey = await catalog.loadConnectionApiKey("team-1", "connection-1");

  assert.equal(model.modelId, "qwen3");
  assert.equal(connection.baseUrl, "http://127.0.0.1:11434/v1");
  assert.equal(apiKey, "local-key");
});

function databaseWith(rows: SqlRow[]): LocalSqlDatabase {
  return {
    async get<T extends SqlRow>(sql: string) {
      const row = rows.find((row) => sql.includes("language_models")
        ? "model_id" in row
        : "secret_ref" in row);
      return (row as T | undefined) ?? null;
    },
    async all() {
      return [];
    },
    async run() {},
    async transaction(operation) {
      return operation();
    },
  };
}
