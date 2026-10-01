import {type DocumentCollections, type Documents} from "../../../../db/schema.js";
import {type DocumentCollection} from "../../domain/entities/document-collection.js";
import {
  cloneDocumentData,
  type DocumentData,
  type DocumentRecord,
  validateDocumentData,
} from "../../domain/entities/document.js";

export type DocumentRow = Documents;

export type DocumentCollectionRow = DocumentCollections;

export function documentFromRow(row: DocumentRow): DocumentRecord {
  return {
    id: row.id,
    teamId: row.team_id,
    collectionId: row.collection_id,
    data: documentDataFromJson(row.data_json),
    version: row.version,
    createdAt: timestampFrom(row.created_at),
    updatedAt: timestampFrom(row.updated_at),
  };
}

export function documentCollectionFromRow(row: DocumentCollectionRow): DocumentCollection {
  return {
    id: row.id,
    teamId: row.team_id,
    displayName: row.display_name,
    createdAt: timestampFrom(row.created_at),
    updatedAt: timestampFrom(row.updated_at),
  };
}

export function documentDataJson(data: DocumentData): string {
  return JSON.stringify(cloneDocumentData(data));
}

function documentDataFromJson(value: string): DocumentData {
  try {
    const parsed: unknown = JSON.parse(value);
    validateDocumentData(parsed as DocumentData);
    return cloneDocumentData(parsed as DocumentData);
  } catch (_) {
    throw new Error("Ein gespeicherter Datensatz ist ungültig.");
  }
}

function timestampFrom(value: string): Date {
  const timestamp = new Date(value.includes("T") ? value : `${value.replace(" ", "T")}Z`);
  if (Number.isNaN(timestamp.getTime())) throw new Error("Der Zeitstempel des Datensatzes ist ungültig.");
  return timestamp;
}
