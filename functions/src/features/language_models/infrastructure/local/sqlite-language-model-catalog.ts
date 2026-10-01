import {and, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {languageModelConnections, languageModels} from "../../../../db/schema.js";
import {
  defaultLanguageModelCapabilities,
  languageModelProviders,
  type LanguageModel,
  type LanguageModelCapabilities,
  type LanguageModelConnection,
  type LanguageModelProvider,
} from "../../domain/entities/language-model.js";
import {type LanguageModelCatalog} from "../../domain/repositories/language-model-catalog.js";
import {type LocalLanguageModelSecretStore} from "./local-language-model-secret-store.js";

export class SQLiteLanguageModelCatalog implements LanguageModelCatalog {
  constructor(
    private readonly database: RuntimeExecutor,
    private readonly secretStore: LocalLanguageModelSecretStore,
  ) {}

  async loadModel(teamId: string, modelId: string): Promise<LanguageModel> {
    const row = (await this.database.select({id: languageModels.id, connection_id: languageModels.connection_id, name: languageModels.name, model_id: languageModels.model_id, capabilities_json: languageModels.capabilities_json}).from(languageModels).where(and(eq(languageModels.team_id, teamId), eq(languageModels.id, modelId))).get()) ?? null;
    if (!row) throw new Error("Das Sprachmodell wurde nicht gefunden.");
    return {
      id: requiredString(row.id, "Sprachmodell"),
      teamId,
      connectionId: requiredString(row.connection_id, "Sprachmodell"),
      name: requiredString(row.name, "Sprachmodell"),
      modelId: requiredString(row.model_id, "Sprachmodell"),
      capabilities: capabilitiesFrom(row.capabilities_json),
    };
  }

  async loadConnection(
    teamId: string,
    connectionId: string,
  ): Promise<LanguageModelConnection> {
    const row = await this.connectionRow(teamId, connectionId);
    const provider = row.provider;
    if (!isProvider(provider)) throw new Error("Die Sprachmodell-Verbindung ist ungültig.");
    const baseUrl = optionalString(row.base_url);
    return {
      id: requiredString(row.id, "Sprachmodell-Verbindung"),
      teamId,
      name: requiredString(row.name, "Sprachmodell-Verbindung"),
      provider,
      ...(baseUrl ? {baseUrl} : {}),
    };
  }

  async loadConnectionApiKey(
    teamId: string,
    connectionId: string,
  ): Promise<string> {
    const row = await this.connectionRow(teamId, connectionId);
    const secretRef = requiredString(row.secret_ref, "Sprachmodell-Verbindung");
    const apiKey = await this.secretStore.read(secretRef);
    if (!apiKey) throw new Error("Für die Sprachmodell-Verbindung fehlt ein API-Key.");
    return apiKey;
  }

  private async connectionRow(teamId: string, connectionId: string): Promise<Record<string, unknown>> {
    const row = (await this.database.select({id: languageModelConnections.id, name: languageModelConnections.name, provider: languageModelConnections.provider, base_url: languageModelConnections.base_url, secret_ref: languageModelConnections.secret_ref}).from(languageModelConnections).where(and(eq(languageModelConnections.team_id, teamId), eq(languageModelConnections.id, connectionId))).get()) ?? null;
    if (!row) throw new Error("Die Sprachmodell-Verbindung wurde nicht gefunden.");
    return row;
  }
}

function capabilitiesFrom(value: unknown): LanguageModelCapabilities {
  if (typeof value !== "string") return defaultLanguageModelCapabilities;
  try {
    const parsed = JSON.parse(value);
    if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
      return defaultLanguageModelCapabilities;
    }
    const capabilities = parsed as Record<string, unknown>;
    return {
      textGeneration: capabilities.textGeneration === true,
      imageInput: capabilities.imageInput === true,
      structuredOutput: capabilities.structuredOutput === true,
      toolCalling: capabilities.toolCalling === true,
      imageGeneration: capabilities.imageGeneration === true,
    };
  } catch (_) {
    return defaultLanguageModelCapabilities;
  }
}

function requiredString(value: unknown, entity: string): string {
  if (typeof value === "string" && value.length > 0) return value;
  throw new Error(`${entity} ist ungültig.`);
}

function optionalString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function isProvider(value: unknown): value is LanguageModelProvider {
  return typeof value === "string" && languageModelProviders.includes(
    value as LanguageModelProvider,
  );
}
