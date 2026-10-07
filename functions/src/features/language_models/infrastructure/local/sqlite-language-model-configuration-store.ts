import {languageModelsQuery} from "./local-language-model-queries.js";
import {capabilitiesFromRecord} from "../../domain/entities/language-model.js";
import {and, eq, sql} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor, type RuntimeTransaction} from "../../../../db/database.js";
import {languageModelConnections, languageModels, type LanguageModelConnections, type LanguageModels} from "../../../../db/schema.js";
import {
  type LanguageModel,
  type LanguageModelCapabilities,
  type LanguageModelConnection,
  type LanguageModelProvider,
} from "../../domain/entities/language-model.js";
import {
  type LanguageModelConfigurationStore,
  type SaveLanguageModelConfiguration,
  type SaveLanguageModelConnectionConfiguration,
} from "../../domain/repositories/language-model-configuration-store.js";
import {type TransactionalLanguageModelSecretStore} from "./local-language-model-secret-store.js";

type ModelRow = Pick<LanguageModels, "capabilities_json" | "connection_id" | "id" | "model_id" | "name">;

type ConnectionRow = Pick<LanguageModelConnections, "base_url" | "id" | "name" | "provider">;

export class SQLiteLanguageModelConfigurationStore
    implements LanguageModelConfigurationStore {
  constructor(
    private readonly database: RuntimeExecutor,
    private readonly secrets: TransactionalLanguageModelSecretStore,
  ) {}

  async list(teamId: string): Promise<LanguageModel[]> {
    const rows = await languageModelsQuery(this.database).where(eq(languageModelConnections.team_id, teamId)).orderBy(sql`${languageModels.name} COLLATE NOCASE`);
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
    const models = input.models.map((model) => ({...model, id: randomUUID(), teamId: input.teamId, connectionId}));
    const secretRef = `language-model/${input.teamId}/${connectionId}`;
    await this.database.transaction((tx) => this.persistConnection(tx, input, connectionId, secretRef, models));
    return models;
  }

  private async persistConnection(tx: RuntimeTransaction, input: SaveLanguageModelConnectionConfiguration,
    connectionId: string, secretRef: string, models: LanguageModel[]): Promise<void> {
    await tx.insert(languageModelConnections).values({id: connectionId, team_id: input.teamId,
      name: input.connection.name, provider: input.connection.provider, base_url: input.connection.baseUrl ?? null, secret_ref: secretRef});
    await this.secrets.withDatabase(tx).write(secretRef, input.apiKey);
    for (const model of models) {
      await tx.insert(languageModels).values({id: model.id, connection_id: model.connectionId,
        name: model.name, model_id: model.modelId, capabilities_json: JSON.stringify(model.capabilities)});
    }
  }

  async listConnections(teamId: string): Promise<LanguageModelConnection[]> {
    const rows = await this.database.select({id: languageModelConnections.id, name: languageModelConnections.name, provider: languageModelConnections.provider, base_url: languageModelConnections.base_url}).from(languageModelConnections).where(eq(languageModelConnections.team_id, teamId)).orderBy(sql`${languageModelConnections.name} COLLATE NOCASE`);
    return rows.map((row) => connectionFromRow(teamId, row));
  }

  async deleteConnection(teamId: string, connectionId: string): Promise<void> {
    await this.database.transaction(async (tx) => {
      const connection = await tx.select({secret_ref: languageModelConnections.secret_ref})
        .from(languageModelConnections).where(and(
          eq(languageModelConnections.id, connectionId), eq(languageModelConnections.team_id, teamId),
        )).get();
      if (connection === undefined) return;
      await tx.delete(languageModelConnections).where(and(
        eq(languageModelConnections.id, connectionId), eq(languageModelConnections.team_id, teamId),
      ));
      await this.secrets.withDatabase(tx).delete(connection.secret_ref);
    });
  }
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

function connectionFromRow(teamId: string, row: ConnectionRow): LanguageModelConnection {
  return {
    id: row.id,
    teamId,
    name: row.name,
    provider: row.provider as LanguageModelProvider,
    baseUrl: row.base_url ?? undefined,
  };
}

function capabilitiesFrom(value: string): LanguageModelCapabilities {
  const parsed: unknown = JSON.parse(value);
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("Das Sprachmodell ist ungültig.");
  }
  const capabilities = parsed as Record<string, unknown>;
  return capabilitiesFromRecord(capabilities);
}
