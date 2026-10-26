import {FieldValue, type DocumentData} from "firebase-admin/firestore";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelCatalog} from "../../domain/repositories/model-catalog.js";
import {type SystemModelCatalog} from "../../domain/repositories/system-model-catalog.js";
import {type SystemModelRegistry} from "../../domain/repositories/system-model-registry.js";
import {
  modelCatalogEntryData,
  modelCatalogEntryFromData,
} from "../model-catalog-entry-codec.js";

export class FirestoreModelCatalog implements ModelCatalog, SystemModelCatalog, SystemModelRegistry {
  async save(entry: ModelCatalogEntry): Promise<void> {
    const reference = modelsReference().doc(entry.id);
    await getDatabase().runTransaction(async (transaction) => {
      const existing = await transaction.get(reference);
      transaction.set(reference, documentFrom(entry, existing.exists), {merge: true});
    });
  }

  async listAvailableFor(teamId: string): Promise<readonly ModelCatalogEntry[]> {
    const [systemEntries, teamSnapshot] = await Promise.all([
      this.listSystemEntries(),
      modelsReference().where("scope", "==", "team").where("teamId", "==", teamId).get(),
    ]);
    return [...systemEntries, ...teamSnapshot.docs.map(documentToEntry)].sort(compareEntries);
  }

  async listSystemEntries(): Promise<readonly ModelCatalogEntry[]> {
    const snapshot = await modelsReference().where("scope", "==", "system").get();
    return snapshot.docs.map(documentToEntry).sort(compareEntries);
  }

  async findAvailableFor(
    teamId: string,
    modelId: string,
  ): Promise<ModelCatalogEntry | null> {
    const snapshot = await modelsReference().doc(modelId).get();
    if (!snapshot.exists) return null;
    const entry = documentToEntry(snapshot);
    return availableFor(entry, teamId) ? entry : null;
  }

  async findSystemEntry(modelId: string): Promise<ModelCatalogEntry | null> {
    const snapshot = await modelsReference().doc(modelId).get();
    if (!snapshot.exists) return null;
    const entry = documentToEntry(snapshot);
    return entry.scope.type === "system" ? entry : null;
  }
}

function documentFrom(entry: ModelCatalogEntry, exists: boolean) {
  return {
    ...modelCatalogEntryData(entry),
    updatedAt: FieldValue.serverTimestamp(),
    ...(!exists ? {createdAt: FieldValue.serverTimestamp()} : {}),
  };
}

function documentToEntry(
  document: {id: string; data(): DocumentData | undefined},
): ModelCatalogEntry {
  const data = document.data() ?? {};
  return modelCatalogEntryFromData({
    id: document.id,
    title: data.title,
    description: data.description,
    translations: data.translations,
    task: data.task,
    languages: data.languages,
    tags: data.tags,
    scope: data.scope,
    teamId: data.teamId,
    runtime: data.runtime,
    artifactReference: data.artifactReference,
    contract: data.contract,
  });
}

function availableFor(entry: ModelCatalogEntry, teamId: string): boolean {
  return entry.scope.type === "system" || entry.scope.teamId === teamId;
}

function compareEntries(left: ModelCatalogEntry, right: ModelCatalogEntry): number {
  return left.title.localeCompare(right.title, "de") || left.id.localeCompare(right.id);
}

function modelsReference() {
  return getDatabase().collection("modelCatalog");
}
