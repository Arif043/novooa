import {and, count, eq, inArray} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {documents} from "../../../../db/schema.js";
import {
  type CreateDocumentCollectionInput, type DocumentCollection, type DocumentCollectionNameInput,
  type DocumentCollectionRef, type RenameDocumentCollectionInput,
} from "../../domain/entities/document-collection.js";
import {type FindDocumentsInput, validateFindDocumentsInput} from "../../domain/entities/document-filter.js";
import {
  type CreateDocumentInput, type CreateDocumentsInput, type DeleteDocumentsInput, type DocumentRecord,
  type FindDocumentByIdInput, type UpdateDocumentInput, type UpsertDocumentInput, cloneDocumentData,
  validateCreateDocumentInput, validateCreateDocumentsInput, validateDeleteDocumentsInput,
  validateFindDocumentByIdInput, validateUpdateDocumentInput,
} from "../../domain/entities/document.js";
import {type DocumentStore} from "../../domain/repositories/document-store.js";
import {SQLiteDocumentCollections} from "./sqlite-document-collections.js";
import {sqlFilterFor} from "./sqlite-document-filter.js";
import {documentDataJson, documentFromRow} from "./sqlite-document-row.js";
import {sqlOrderFor} from "./sqlite-document-sort.js";

export class SQLiteDocumentStore implements DocumentStore {
  private readonly collections: SQLiteDocumentCollections;

  constructor(private readonly database: RuntimeExecutor) {
    this.collections = new SQLiteDocumentCollections(database);
  }

  createCollection(input: CreateDocumentCollectionInput): Promise<DocumentCollection> {
    return this.collections.create(input);
  }

  ensureCollection(input: DocumentCollectionNameInput): Promise<DocumentCollection> {
    return this.collections.ensure(input);
  }

  findCollectionByName(input: DocumentCollectionNameInput): Promise<DocumentCollection | null> {
    return this.collections.findByName(input);
  }

  listCollections(teamId: string): Promise<DocumentCollection[]> {
    return this.collections.list(teamId);
  }

  renameCollection(input: RenameDocumentCollectionInput): Promise<DocumentCollection | null> {
    return this.collections.rename(input);
  }

  deleteCollection(input: DocumentCollectionRef): Promise<boolean> {
    return this.collections.delete(input);
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
      .orderBy(...sqlOrderFor(input.sort)).limit(input.limit ?? 100).offset(input.offset ?? 0);
    return rows.map(documentFromRow);
  }

  async create(input: CreateDocumentInput): Promise<DocumentRecord> {
    validateCreateDocumentInput(input);
    return this.database.transaction((tx) => new SQLiteDocumentStore(tx).insertDocument(input, input.documentId ?? randomUUID()));
  }

  async createMany(input: CreateDocumentsInput): Promise<number> {
    validateCreateDocumentsInput(input);
    return this.database.transaction(async (tx) => {
      if (!await new SQLiteDocumentCollections(tx).exists({teamId: input.teamId, id: input.collectionId})) {
        throw new Error("Die Datensammlung wurde nicht gefunden.");
      }
      const timestamp = new Date().toISOString();
      const rows = input.items.map((data) => ({id: randomUUID(), team_id: input.teamId, collection_id: input.collectionId,
        data_json: documentDataJson(cloneDocumentData(data)), version: 1, created_at: timestamp, updated_at: timestamp}));
      // SQLite begrenzt die Parameter je Anweisung; 100 Zeilen à 7 Spalten bleiben darunter.
      for (let start = 0; start < rows.length; start += 100) await tx.insert(documents).values(rows.slice(start, start + 100));
      return rows.length;
    });
  }

  async deleteDocuments(input: DeleteDocumentsInput): Promise<number> {
    validateDeleteDocumentsInput(input);
    if (input.documentIds?.length === 0) return 0;
    const scope = and(eq(documents.team_id, input.teamId), eq(documents.collection_id, input.collectionId),
      input.documentIds === undefined ? undefined : inArray(documents.id, [...input.documentIds]));
    const removed = await this.database.delete(documents).where(scope).returning({id: documents.id});
    return removed.length;
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

  private collectionExists(teamId: string, collectionId: string): Promise<boolean> {
    return this.collections.exists({teamId, id: collectionId});
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
