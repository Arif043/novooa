import {and, asc, count, desc, eq, sql} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {documentCollections, documents} from "../../../../db/schema.js";
import {
  type CreateDocumentCollectionInput, type DocumentCollection, type DocumentCollectionNameInput,
  validateDocumentCollectionInput, validateDocumentCollectionNameInput
} from "../../domain/entities/document-collection.js";
import {type FindDocumentsInput, validateFindDocumentsInput} from "../../domain/entities/document-filter.js";
import {
  type CreateDocumentInput, type DocumentRecord, type FindDocumentByIdInput, type UpdateDocumentInput,
  type UpsertDocumentInput, cloneDocumentData, validateCreateDocumentInput, validateFindDocumentByIdInput,
  validateUpdateDocumentInput
} from "../../domain/entities/document.js";
import {type DocumentStore} from "../../domain/repositories/document-store.js";
import {sqlFilterFor} from "./sqlite-document-filter.js";
import {documentCollectionFromRow, documentDataJson, documentFromRow} from "./sqlite-document-row.js";

export class SQLiteDocumentStore implements DocumentStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async createCollection(input: CreateDocumentCollectionInput): Promise<DocumentCollection> {
    validateDocumentCollectionInput(input);
    return this.database.transaction(async (tx) => {
      if (await new SQLiteDocumentStore(tx).collectionExists(input.teamId, input.id)) throw new Error("Die Datensammlung existiert bereits.");
      const timestamp = new Date().toISOString();
      const values = {id: input.id, team_id: input.teamId, display_name: input.displayName, created_at: timestamp, updated_at: timestamp};
      await tx.insert(documentCollections).values(values);
      return documentCollectionFromRow(values);
    });
  }

  async ensureCollection(input: DocumentCollectionNameInput): Promise<DocumentCollection> {
    validateDocumentCollectionNameInput(input);
    return this.database.transaction(async (tx) => {
      const store = new SQLiteDocumentStore(tx);
      const existing = await store.findCollectionByName(input);
      if (existing !== null) return existing;
      const timestamp = new Date().toISOString();
      await tx.insert(documentCollections).values({id: randomUUID(), team_id: input.teamId,
        display_name: input.displayName, created_at: timestamp, updated_at: timestamp}).onConflictDoNothing();
      const collection = await store.findCollectionByName(input);
      if (collection === null) throw new Error("Die Datensammlung konnte nicht angelegt werden.");
      return collection;
    });
  }

  async findCollectionByName(input: DocumentCollectionNameInput): Promise<DocumentCollection | null> {
    validateDocumentCollectionNameInput(input);
    const row = await this.database.select().from(documentCollections)
      .where(and(eq(documentCollections.team_id, input.teamId), eq(documentCollections.display_name, input.displayName))).get();
    return row ? documentCollectionFromRow(row) : null;
  }

  async listCollections(teamId: string): Promise<DocumentCollection[]> {
    const rows = await this.database.select().from(documentCollections).where(eq(documentCollections.team_id, teamId))
      .orderBy(sql`${documentCollections.display_name} COLLATE BINARY`);
    return rows.map(documentCollectionFromRow);
  }

  async countDocuments(input: FindDocumentsInput): Promise<number> {
    validateFindDocumentsInput(input);
    const row = await this.database.select({count: count()}).from(documents).where(documentScope(input)).get();
    return row?.count ?? 0;
  }

  async delete(input: FindDocumentByIdInput): Promise<boolean> {
    validateFindDocumentByIdInput(input);
    const removed = await this.database.delete(documents).where(and(
      eq(documents.team_id, input.teamId), eq(documents.collection_id, input.collectionId), eq(documents.id, input.documentId),
    )).returning({id: documents.id});
    return removed.length > 0;
  }

  async findOne(input: FindDocumentsInput): Promise<DocumentRecord | null> {
    return (await this.findMany({...input, limit: 1}))[0] ?? null;
  }

  async findById(input: FindDocumentByIdInput): Promise<DocumentRecord | null> {
    validateFindDocumentByIdInput(input);
    return this.documentById(input.teamId, input.collectionId, input.documentId);
  }

  async findMany(input: FindDocumentsInput): Promise<DocumentRecord[]> {
    validateFindDocumentsInput(input);
    const rows = await this.database.select().from(documents).where(documentScope(input))
      .orderBy(desc(documents.updated_at), asc(documents.id)).limit(input.limit ?? 100);
    return rows.map(documentFromRow);
  }

  async create(input: CreateDocumentInput): Promise<DocumentRecord> {
    validateCreateDocumentInput(input);
    return this.database.transaction((tx) => new SQLiteDocumentStore(tx).insertDocument(input, input.documentId ?? randomUUID()));
  }

  async update(input: UpdateDocumentInput): Promise<DocumentRecord> {
    validateUpdateDocumentInput(input);
    return this.database.transaction((tx) => new SQLiteDocumentStore(tx).updateDocument(input));
  }

  async upsert(input: UpsertDocumentInput): Promise<DocumentRecord> {
    validateUpdateDocumentInput(input);
    return this.database.transaction(async (tx) => {
      const store = new SQLiteDocumentStore(tx);
      const current = await store.documentById(input.teamId, input.collectionId, input.documentId);
      return current === null ? store.insertDocument(input, input.documentId) : store.updateExistingDocument(input, current);
    });
  }

  private async insertDocument(input: CreateDocumentInput, documentId: string): Promise<DocumentRecord> {
    if (!await this.collectionExists(input.teamId, input.collectionId)) throw new Error("Die Datensammlung wurde nicht gefunden.");
    if (await this.documentById(input.teamId, input.collectionId, documentId)) throw new Error("Die Datensatz-ID existiert bereits.");
    const timestamp = new Date().toISOString();
    const values = {id: documentId, team_id: input.teamId, collection_id: input.collectionId,
      data_json: documentDataJson(cloneDocumentData(input.data)), version: 1, created_at: timestamp, updated_at: timestamp};
    await this.database.insert(documents).values(values);
    return documentFromRow(values);
  }

  private async updateDocument(input: UpdateDocumentInput): Promise<DocumentRecord> {
    const current = await this.documentById(input.teamId, input.collectionId, input.documentId);
    if (current === null) throw new Error("Der Datensatz wurde nicht gefunden.");
    return this.updateExistingDocument(input, current);
  }

  private async updateExistingDocument(input: UpdateDocumentInput, current: DocumentRecord): Promise<DocumentRecord> {
    if (input.expectedVersion !== undefined && input.expectedVersion !== current.version) {
      throw new Error("Der Datensatz wurde inzwischen geändert.");
    }
    const timestamp = new Date().toISOString();
    const version = current.version + 1;
    const data = cloneDocumentData(input.data);
    await this.database.update(documents).set({data_json: documentDataJson(data), version, updated_at: timestamp})
      .where(and(eq(documents.team_id, input.teamId), eq(documents.collection_id, input.collectionId), eq(documents.id, input.documentId)));
    return {...current, data, version, updatedAt: new Date(timestamp)};
  }

  private async collectionExists(teamId: string, collectionId: string): Promise<boolean> {
    const row = await this.database.select({id: documentCollections.id}).from(documentCollections)
      .where(and(eq(documentCollections.team_id, teamId), eq(documentCollections.id, collectionId))).get();
    return row !== undefined;
  }

  private async documentById(teamId: string, collectionId: string, documentId: string): Promise<DocumentRecord | null> {
    const row = await this.database.select().from(documents).where(and(eq(documents.team_id, teamId),
      eq(documents.collection_id, collectionId), eq(documents.id, documentId))).get();
    return row ? documentFromRow(row) : null;
  }
}

function documentScope(input: FindDocumentsInput) {
  return and(eq(documents.team_id, input.teamId), eq(documents.collection_id, input.collectionId),
    ...(input.filters ?? []).map(sqlFilterFor));
}
