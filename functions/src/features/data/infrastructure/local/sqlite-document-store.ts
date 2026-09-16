import {randomUUID} from "node:crypto";
import {
  type CreateDocumentCollectionInput,
  type DocumentCollection,
  validateDocumentCollectionInput,
} from "../../domain/entities/document-collection.js";
import {
  type CreateDocumentInput,
  cloneDocumentData,
  type DocumentRecord,
  type UpdateDocumentInput,
  type UpsertDocumentInput,
  validateCreateDocumentInput,
  validateUpdateDocumentInput,
} from "../../domain/entities/document.js";
import {
  type FindDocumentsInput,
  validateFindDocumentsInput,
} from "../../domain/entities/document-filter.js";
import {type DocumentStore} from "../../domain/repositories/document-store.js";
import {type LocalSqlDatabase} from "../../../../shared/local/local-sql-database.js";
import {sqlFilterFor} from "./sqlite-document-filter.js";
import {
  type DocumentCollectionRow,
  type DocumentRow,
  documentDataJson,
  documentFromRow,
} from "./sqlite-document-row.js";

export class SQLiteDocumentStore implements DocumentStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async createCollection(input: CreateDocumentCollectionInput): Promise<DocumentCollection> {
    validateDocumentCollectionInput(input);
    return this.database.transaction(async () => {
      if (await this.collectionExists(input.teamId, input.id)) throw new Error("Die Datensammlung existiert bereits.");
      const timestamp = new Date().toISOString();
      await this.database.run(insertCollectionSql(), [input.id, input.teamId, input.displayName, timestamp, timestamp]);
      return {...input, createdAt: new Date(timestamp), updatedAt: new Date(timestamp)};
    });
  }

  async findOne(input: FindDocumentsInput): Promise<DocumentRecord | null> {
    const documents = await this.findMany({...input, limit: 1});
    return documents[0] ?? null;
  }

  async findMany(input: FindDocumentsInput): Promise<DocumentRecord[]> {
    validateFindDocumentsInput(input);
    const filters = (input.filters ?? []).map(sqlFilterFor);
    const query = queryFor(input, filters);
    const rows = await this.database.all<DocumentRow>(query.sql, query.parameters);
    return rows.map(documentFromRow);
  }

  async create(input: CreateDocumentInput): Promise<DocumentRecord> {
    validateCreateDocumentInput(input);
    return this.database.transaction(() => this.insertDocument(input, input.documentId ?? randomUUID()));
  }

  async update(input: UpdateDocumentInput): Promise<DocumentRecord> {
    validateUpdateDocumentInput(input);
    return this.database.transaction(() => this.updateDocument(input));
  }

  async upsert(input: UpsertDocumentInput): Promise<DocumentRecord> {
    validateUpdateDocumentInput(input);
    return this.database.transaction(async () => {
      const current = await this.documentById(input.teamId, input.collectionId, input.documentId);
      if (current === null) return this.insertDocument(input, input.documentId);
      return this.updateExistingDocument(input, current);
    });
  }

  private async insertDocument(input: CreateDocumentInput, documentId: string): Promise<DocumentRecord> {
    await this.requireCollection(input.teamId, input.collectionId);
    const existing = await this.documentById(input.teamId, input.collectionId, documentId);
    if (existing !== null) throw new Error("Die Datensatz-ID existiert bereits.");
    const timestamp = new Date().toISOString();
    const data = cloneDocumentData(input.data);
    await this.database.run(insertDocumentSql(), [
      documentId, input.teamId, input.collectionId, documentDataJson(data), timestamp, timestamp,
    ]);
    return documentFromInput(input, documentId, data, 1, timestamp, timestamp);
  }

  private async updateDocument(input: UpdateDocumentInput): Promise<DocumentRecord> {
    const current = await this.documentById(input.teamId, input.collectionId, input.documentId);
    if (current === null) throw new Error("Der Datensatz wurde nicht gefunden.");
    return this.updateExistingDocument(input, current);
  }

  private async updateExistingDocument(
    input: UpdateDocumentInput,
    current: DocumentRecord,
  ): Promise<DocumentRecord> {
    if (input.expectedVersion !== undefined && input.expectedVersion !== current.version) {
      throw new Error("Der Datensatz wurde inzwischen geändert.");
    }
    const timestamp = new Date().toISOString();
    const version = current.version + 1;
    const data = cloneDocumentData(input.data);
    await this.database.run(updateDocumentSql(), [
      documentDataJson(data), version, timestamp, input.teamId, input.collectionId, input.documentId,
    ]);
    return {...current, data, version, updatedAt: new Date(timestamp)};
  }

  private async requireCollection(teamId: string, collectionId: string): Promise<void> {
    if (!await this.collectionExists(teamId, collectionId)) {
      throw new Error("Die Datensammlung wurde nicht gefunden.");
    }
  }

  private async collectionExists(teamId: string, collectionId: string): Promise<boolean> {
    const row = await this.database.get<DocumentCollectionRow>(
      "SELECT id, team_id, display_name, created_at, updated_at FROM document_collections WHERE team_id = ? AND id = ?",
      [teamId, collectionId],
    );
    return row !== null;
  }

  private async documentById(
    teamId: string,
    collectionId: string,
    documentId: string,
  ): Promise<DocumentRecord | null> {
    const row = await this.database.get<DocumentRow>(selectDocumentByIdSql(), [teamId, collectionId, documentId]);
    return row === null ? null : documentFromRow(row);
  }
}

function documentFromInput(
  input: CreateDocumentInput,
  id: string,
  data: DocumentRecord["data"],
  version: number,
  createdAt: string,
  updatedAt: string,
): DocumentRecord {
  return {
    id, teamId: input.teamId, collectionId: input.collectionId, data, version,
    createdAt: new Date(createdAt), updatedAt: new Date(updatedAt),
  };
}

function queryFor(input: FindDocumentsInput, filters: ReturnType<typeof sqlFilterFor>[]) {
  const predicates = ["team_id = ?", "collection_id = ?", ...filters.map((filter) => filter.sql)];
  const parameters = [input.teamId, input.collectionId, ...filters.flatMap((filter) => filter.parameters), input.limit ?? 100];
  return {
    sql: `SELECT id, team_id, collection_id, data_json, version, created_at, updated_at
      FROM documents WHERE ${predicates.join(" AND ")} ORDER BY updated_at DESC, id ASC LIMIT ?`,
    parameters,
  };
}

function insertCollectionSql(): string {
  return `INSERT INTO document_collections(id, team_id, display_name, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?)`;
}

function insertDocumentSql(): string {
  return `INSERT INTO documents(id, team_id, collection_id, data_json, version, created_at, updated_at)
    VALUES (?, ?, ?, ?, 1, ?, ?)`;
}

function selectDocumentByIdSql(): string {
  return `SELECT id, team_id, collection_id, data_json, version, created_at, updated_at
    FROM documents WHERE team_id = ? AND collection_id = ? AND id = ?`;
}

function updateDocumentSql(): string {
  return `UPDATE documents SET data_json = ?, version = ?, updated_at = ?
    WHERE team_id = ? AND collection_id = ? AND id = ?`;
}
