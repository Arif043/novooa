import {
  cloneDocumentData,
  type DocumentData,
  type DocumentRecord,
  validateDocumentData,
} from "../../domain/entities/document.js";
import {type DocumentCollection} from "../../domain/entities/document-collection.js";
import {type SqlRow} from "../../../../shared/local/local-sql-database.js";

export type DocumentRow = SqlRow & {
  id: string;
  team_id: string;
  collection_id: string;
  data_json: string;
  version: number;
  created_at: string;
  updated_at: string;
};

export type DocumentCollectionRow = SqlRow & {
  id: string;
  team_id: string;
  display_name: string;
  created_at: string;
  updated_at: string;
};

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
