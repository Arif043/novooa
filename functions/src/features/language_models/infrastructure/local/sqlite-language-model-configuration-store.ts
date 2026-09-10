import {randomUUID} from "node:crypto";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {
  type LanguageModel,
  type LanguageModelCapabilities,
} from "../../domain/entities/language-model.js";
import {
  type LanguageModelConfigurationStore,
  type SaveLanguageModelConnectionConfiguration,
  type SaveLanguageModelConfiguration,
} from "../../domain/repositories/language-model-configuration-store.js";
import {type LocalLanguageModelSecretStore} from "./local-language-model-secret-store.js";

type ModelRow = SqlRow & {
  capabilities_json: string;
  connection_id: string;
  id: string;
  model_id: string;
  name: string;
};

export class SQLiteLanguageModelConfigurationStore
    implements LanguageModelConfigurationStore {
  constructor(
    private readonly database: LocalSqlDatabase,
    private readonly secrets: LocalLanguageModelSecretStore,
  ) {}

  async list(teamId: string): Promise<LanguageModel[]> {
    const rows = await this.database.all<ModelRow>(
      `SELECT id, connection_id, name, model_id, capabilities_json
       FROM language_models WHERE team_id = ? ORDER BY name COLLATE NOCASE`,
      [teamId],
    );
    return rows.map((row) => modelFromRow(teamId, row));
  }

  async save(input: SaveLanguageModelConfiguration): Promise<LanguageModel> {
    const [model] = await this.saveConnection({...input, models: [input.model]});
    return model;
  }

  async saveConnection(
    input: SaveLanguageModelConnectionConfiguration,
  ): Promise<LanguageModel[]> {
    const connectionId = randomUUID();
    const models = input.models.map((model) => ({id: randomUUID(), ...model}));
    const secretRef = `language-model/${connectionId}`;
    await this.database.transaction(async () => {
      await this.database.run(connectionSql(), connectionValues(input, connectionId, secretRef));
      await this.secrets.write(secretRef, input.apiKey);
      for (const model of models) {
        await this.database.run(modelSql(), modelValues(model, input.teamId, model.id, connectionId));
      }
    });
    return models.map((model) => ({
      id: model.id,
      teamId: input.teamId,
      connectionId,
      name: model.name,
      modelId: model.modelId,
      capabilities: model.capabilities,
    }));
  }
}

function connectionSql(): string {
  return `INSERT INTO language_model_connections
    (id, team_id, name, provider, base_url, secret_ref) VALUES (?, ?, ?, ?, ?, ?)`;
}

function connectionValues(
  input: SaveLanguageModelConnectionConfiguration,
  id: string,
  secretRef: string,
): [string, string, string, string, string | null, string] {
  return [id, input.teamId, input.connection.name, input.connection.provider,
    input.connection.baseUrl ?? null, secretRef];
}

function modelSql(): string {
  return `INSERT INTO language_models
    (id, team_id, connection_id, name, model_id, capabilities_json) VALUES (?, ?, ?, ?, ?, ?)`;
}

function modelValues(
  model: SaveLanguageModelConfiguration["model"],
  teamId: string,
  id: string,
  connectionId: string,
): [string, string, string, string, string, string] {
  return [id, teamId, connectionId, model.name, model.modelId,
    JSON.stringify(model.capabilities)];
}

function modelFromRow(teamId: string, row: ModelRow): LanguageModel {
  return {
    id: row.id,
    teamId,
    connectionId: row.connection_id,
    name: row.name,
    modelId: row.model_id,
    capabilities: capabilitiesFrom(row.capabilities_json),
  };
}

function capabilitiesFrom(value: string): LanguageModelCapabilities {
  const parsed: unknown = JSON.parse(value);
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("Das Sprachmodell ist ungültig.");
  }
  const capabilities = parsed as Record<string, unknown>;
  return {
    textGeneration: capabilities.textGeneration === true,
    imageInput: capabilities.imageInput === true,
    structuredOutput: capabilities.structuredOutput === true,
    toolCalling: capabilities.toolCalling === true,
    imageGeneration: capabilities.imageGeneration === true,
  };
}
