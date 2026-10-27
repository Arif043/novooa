import {and, eq, ne, sql} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {documentCollections, documents} from "../../../../db/schema.js";
import {
  type CreateDocumentCollectionInput, type DocumentCollection, type DocumentCollectionNameInput, type DocumentCollectionRef,
  DocumentCollectionNameTakenError, type RenameDocumentCollectionInput, validateDocumentCollectionInput,
  validateDocumentCollectionNameInput, validateDocumentCollectionRef, validateRenameDocumentCollectionInput,
} from "../../domain/entities/document-collection.js";
import {documentCollectionFromRow} from "./sqlite-document-row.js";

/** Sammlungs-Operationen des SQLite-Stores; Datensätze bleiben in `SQLiteDocumentStore`. */
export class SQLiteDocumentCollections {
  constructor(private readonly database: RuntimeExecutor) {}

  async create(input: CreateDocumentCollectionInput): Promise<DocumentCollection> {
    validateDocumentCollectionInput(input);
    return this.database.transaction(async (tx) => {
      if (await new SQLiteDocumentCollections(tx).exists(input)) throw new Error("Die Datensammlung existiert bereits.");
      const timestamp = new Date().toISOString();
      const values = {id: input.id, team_id: input.teamId, display_name: input.displayName, created_at: timestamp, updated_at: timestamp};
      await tx.insert(documentCollections).values(values);
      return documentCollectionFromRow(values);
    });
  }

  async ensure(input: DocumentCollectionNameInput): Promise<DocumentCollection> {
    validateDocumentCollectionNameInput(input);
    return this.database.transaction(async (tx) => {
      const collections = new SQLiteDocumentCollections(tx);
      const existing = await collections.findByName(input);
      if (existing !== null) return existing;
      const timestamp = new Date().toISOString();
      await tx.insert(documentCollections).values({id: randomUUID(), team_id: input.teamId,
        display_name: input.displayName, created_at: timestamp, updated_at: timestamp}).onConflictDoNothing();
      const collection = await collections.findByName(input);
      if (collection === null) throw new Error("Die Datensammlung konnte nicht angelegt werden.");
      return collection;
    });
  }

  async findByName(input: DocumentCollectionNameInput): Promise<DocumentCollection | null> {
    validateDocumentCollectionNameInput(input);
    const row = await this.database.select().from(documentCollections)
      .where(and(eq(documentCollections.team_id, input.teamId), eq(documentCollections.display_name, input.displayName))).get();
    return row ? documentCollectionFromRow(row) : null;
  }

  async list(teamId: string): Promise<DocumentCollection[]> {
    const rows = await this.database.select().from(documentCollections).where(eq(documentCollections.team_id, teamId))
      .orderBy(sql`${documentCollections.display_name} COLLATE BINARY`);
    return rows.map(documentCollectionFromRow);
  }

  async rename(input: RenameDocumentCollectionInput): Promise<DocumentCollection | null> {
    validateRenameDocumentCollectionInput(input);
    return this.database.transaction(async (tx) => {
      const taken = await tx.select({id: documentCollections.id}).from(documentCollections).where(and(
        eq(documentCollections.team_id, input.teamId), eq(documentCollections.display_name, input.displayName),
        ne(documentCollections.id, input.collectionId))).get();
      if (taken !== undefined) throw new DocumentCollectionNameTakenError();
      const [row] = await tx.update(documentCollections)
        .set({display_name: input.displayName, updated_at: new Date().toISOString()})
        .where(byRef(input)).returning();
      return row ? documentCollectionFromRow(row) : null;
    });
  }

  /** Löscht die Datensätze ausdrücklich mit — unabhängig davon, ob Fremdschlüssel aktiv sind. */
  async delete(input: DocumentCollectionRef): Promise<boolean> {
    validateDocumentCollectionRef(input);
    return this.database.transaction(async (tx) => {
      await tx.delete(documents).where(and(eq(documents.team_id, input.teamId), eq(documents.collection_id, input.collectionId)));
      const removed = await tx.delete(documentCollections).where(byRef(input)).returning({id: documentCollections.id});
      return removed.length > 0;
    });
  }

  async exists(input: {teamId: string; id: string}): Promise<boolean> {
    const row = await this.database.select({id: documentCollections.id}).from(documentCollections)
      .where(byRef({teamId: input.teamId, collectionId: input.id})).get();
    return row !== undefined;
  }
}

function byRef(input: DocumentCollectionRef) {
  return and(eq(documentCollections.team_id, input.teamId), eq(documentCollections.id, input.collectionId));
}
