import {FieldValue} from "firebase-admin/firestore";
import {
  capabilitiesFromRecord,
  defaultLanguageModelCapabilities,
  languageModelProviders,
  type LanguageModel,
  type LanguageModelCapabilities,
  type LanguageModelConnection,
  type LanguageModelProvider,
} from "../../domain/entities/language-model.js";
import {type LanguageModelCatalog} from "../../domain/repositories/language-model-catalog.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {type CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";

export class FirestoreLanguageModelCatalog implements LanguageModelCatalog {
  constructor(cipher: () => CredentialCipher) {
    this.#cipher = cipher;
  }

  readonly #cipher: () => CredentialCipher;

  async loadModel(teamId: string, modelId: string): Promise<LanguageModel> {
    const snapshot = await models(teamId).doc(modelId).get();
    if (!snapshot.exists) throw new Error("Das Sprachmodell wurde nicht gefunden.");
    return modelFrom(teamId, snapshot.id, snapshot.data());
  }

  async loadConnection(
    teamId: string,
    connectionId: string,
  ): Promise<LanguageModelConnection> {
    const snapshot = await connections(teamId).doc(connectionId).get();
    if (!snapshot.exists) throw new Error("Die Sprachmodell-Verbindung wurde nicht gefunden.");
    return connectionFrom(teamId, snapshot.id, snapshot.data());
  }

  async loadConnectionApiKey(
    teamId: string,
    connectionId: string,
  ): Promise<string> {
    const snapshot = await secrets(teamId).doc(connectionId).get();
    const encryptedApiKey = snapshot.data()?.encryptedApiKey;
    if (typeof encryptedApiKey !== "string" || encryptedApiKey.length === 0) {
      throw new Error("Für die Sprachmodell-Verbindung fehlt ein API-Key.");
    }
    return this.#cipher().decrypt(encryptedApiKey);
  }

  async save(input: {
    teamId: string;
    connectionId?: string;
    modelId?: string;
    connection: Omit<LanguageModelConnection, "id" | "teamId">;
    model: Omit<LanguageModel, "id" | "teamId" | "connectionId">;
    apiKey: string;
  }): Promise<LanguageModel> {
    const connectionReference = input.connectionId
      ? connections(input.teamId).doc(input.connectionId)
      : connections(input.teamId).doc();
    const modelReference = input.modelId
      ? models(input.teamId).doc(input.modelId)
      : models(input.teamId).doc();
    const batch = getDatabase().batch();
    batch.set(connectionReference, {
      teamId: input.teamId,
      name: input.connection.name,
      provider: input.connection.provider,
      ...(input.connection.baseUrl ? {baseUrl: input.connection.baseUrl} : {}),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    batch.set(secrets(input.teamId).doc(connectionReference.id), {
      encryptedApiKey: this.#cipher().encrypt(input.apiKey),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    batch.set(modelReference, {
      teamId: input.teamId,
      connectionId: connectionReference.id,
      name: input.model.name,
      modelId: input.model.modelId,
      capabilities: input.model.capabilities,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    await batch.commit();
    return {
      id: modelReference.id,
      teamId: input.teamId,
      connectionId: connectionReference.id,
      ...input.model,
    };
  }
}

function connections(teamId: string) {
  return getDatabase().collection("teams").doc(teamId)
    .collection("languageModelConnections");
}

function models(teamId: string) {
  return getDatabase().collection("teams").doc(teamId)
    .collection("languageModels");
}

function secrets(teamId: string) {
  return getDatabase().collection("teams").doc(teamId)
    .collection("languageModelSecrets");
}

function connectionFrom(
  teamId: string,
  id: string,
  data: Record<string, unknown> | undefined,
): LanguageModelConnection {
  const provider = data?.provider;
  if (!isProvider(provider)) throw new Error("Die Sprachmodell-Verbindung ist ungültig.");
  const name = data?.name;
  if (typeof name !== "string" || name.trim().length === 0) {
    throw new Error("Die Sprachmodell-Verbindung ist ungültig.");
  }
  const baseUrl = data?.baseUrl;
  return {
    id,
    teamId,
    name,
    provider,
    ...(typeof baseUrl === "string" && baseUrl.length > 0 ? {baseUrl} : {}),
  };
}

function modelFrom(
  teamId: string,
  id: string,
  data: Record<string, unknown> | undefined,
): LanguageModel {
  const connectionId = data?.connectionId;
  const name = data?.name;
  const modelId = data?.modelId;
  if (
    typeof connectionId !== "string" || connectionId.length === 0 ||
    typeof name !== "string" || name.trim().length === 0 ||
    typeof modelId !== "string" || modelId.trim().length === 0
  ) {
    throw new Error("Das Sprachmodell ist ungültig.");
  }
  return {
    id,
    teamId,
    connectionId,
    name,
    modelId,
    capabilities: capabilitiesFrom(data?.capabilities),
  };
}

function capabilitiesFrom(value: unknown): LanguageModelCapabilities {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return defaultLanguageModelCapabilities;
  }
  const capabilities = value as Record<string, unknown>;
  return capabilitiesFromRecord(capabilities);
}

function isProvider(value: unknown): value is LanguageModelProvider {
  return typeof value === "string" && languageModelProviders.includes(
    value as LanguageModelProvider,
  );
}
