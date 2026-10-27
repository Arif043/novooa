import {randomUUID} from "node:crypto";
import {
  type CreateDocumentCollectionInput, type DocumentCollection, type DocumentCollectionNameInput, type DocumentCollectionRef,
  DocumentCollectionNameTakenError, type RenameDocumentCollectionInput, validateDocumentCollectionInput,
  validateDocumentCollectionNameInput, validateDocumentCollectionRef, validateRenameDocumentCollectionInput,
} from "../../domain/entities/document-collection.js";
import {
  type CreateDocumentInput, type CreateDocumentsInput, type DeleteDocumentsInput, type DocumentRecord,
  type FindDocumentByIdInput, type UpdateDocumentInput, type UpsertDocumentInput, validateCreateDocumentInput,
  validateCreateDocumentsInput, validateDeleteDocumentsInput, validateFindDocumentByIdInput, validateUpdateDocumentInput,
} from "../../domain/entities/document.js";
import {type FindDocumentsInput, validateFindDocumentsInput} from "../../domain/entities/document-filter.js";
import {type DocumentStore} from "../../domain/repositories/document-store.js";
import {SerialQueue} from "./serial-queue.js";
import {collectionNamed, keysToDelete, queryDocuments} from "./in-memory-document-query.js";
import {
  collectionKey, copyCollection, copyDocument, copyOrNull, documentFrom, documentKey,
} from "./in-memory-document-records.js";

export class InMemoryDocumentStore implements DocumentStore {
  private readonly collections = new Map<string, DocumentCollection>();
  private readonly documents = new Map<string, DocumentRecord>();
  private readonly queue = new SerialQueue();

  createCollection(input: CreateDocumentCollectionInput): Promise<DocumentCollection> {
    return this.queue.run(() => {
      validateDocumentCollectionInput(input);
      const key = collectionKey(input.teamId, input.id);
      if (this.collections.has(key)) throw new Error("Die Datensammlung existiert bereits.");
      const timestamp = new Date();
      const collection = {...input, createdAt: timestamp, updatedAt: timestamp};
      this.collections.set(key, collection);
      return copyCollection(collection);
    });
  }

  ensureCollection(input: DocumentCollectionNameInput): Promise<DocumentCollection> {
    return this.queue.run(() => {
      validateDocumentCollectionNameInput(input);
      const existing = this.collectionByName(input);
      if (existing !== undefined) return copyCollection(existing);
      const timestamp = new Date();
      const collection = {id: randomUUID(), ...input, createdAt: timestamp, updatedAt: timestamp};
      this.collections.set(collectionKey(input.teamId, collection.id), collection);
      return copyCollection(collection);
    });
  }

  findCollectionByName(input: DocumentCollectionNameInput): Promise<DocumentCollection | null> {
    return this.queue.run(() => {
      validateDocumentCollectionNameInput(input);
      return copyOrNull(this.collectionByName(input));
    });
  }

  listCollections(teamId: string): Promise<DocumentCollection[]> {
    return this.queue.run(() => [...this.collections.values()]
      .filter((collection) => collection.teamId === teamId)
      .sort((left, right) => left.displayName.localeCompare(right.displayName))
      .map(copyCollection));
  }

  renameCollection(input: RenameDocumentCollectionInput): Promise<DocumentCollection | null> {
    return this.queue.run(() => {
      validateRenameDocumentCollectionInput(input);
      const key = collectionKey(input.teamId, input.collectionId);
      const current = this.collections.get(key);
      if (current === undefined) return null;
      if ((this.collectionByName(input)?.id ?? current.id) !== current.id) throw new DocumentCollectionNameTakenError();
      this.collections.set(key, {...current, displayName: input.displayName, updatedAt: new Date()});
      return copyCollection(this.collections.get(key)!);
    });
  }

  deleteCollection(input: DocumentCollectionRef): Promise<boolean> {
    return this.queue.run(() => {
      validateDocumentCollectionRef(input);
      this.removeDocuments(input);
      return this.collections.delete(collectionKey(input.teamId, input.collectionId));
    });
  }

  deleteDocuments(input: DeleteDocumentsInput): Promise<number> {
    return this.queue.run(() => {
      validateDeleteDocumentsInput(input);
      return this.removeDocuments(input);
    });
  }

  createMany(input: CreateDocumentsInput): Promise<number> {
    return this.queue.run(() => {
      validateCreateDocumentsInput(input);
      this.requireCollection(input.teamId, input.collectionId);
      const timestamp = new Date();
      for (const data of input.items) {
        const id = randomUUID();
        this.documents.set(documentKey(input.teamId, input.collectionId, id), documentFrom({...input, data}, id, 1, timestamp, timestamp));
      }
      return input.items.length;
    });
  }

  countDocuments(input: FindDocumentsInput): Promise<number> {
    return this.findMany({...input, limit: 500}).then((documents) => documents.length);
  }

  delete(input: FindDocumentByIdInput): Promise<boolean> {
    return this.queue.run(() => {
      validateFindDocumentByIdInput(input);
      return this.documents.delete(documentKey(input.teamId, input.collectionId, input.documentId));
    });
  }
  findOne(input: FindDocumentsInput): Promise<DocumentRecord | null> {
    return this.findMany({...input, limit: 1}).then((documents) => documents[0] ?? null);
  }

  findById(input: FindDocumentByIdInput): Promise<DocumentRecord | null> {
    return this.queue.run(() => {
      validateFindDocumentByIdInput(input);
      const document = this.documents.get(documentKey(
        input.teamId, input.collectionId, input.documentId,
      ));
      return document === undefined ? null : copyDocument(document);
    });
  }

  findMany(input: FindDocumentsInput): Promise<DocumentRecord[]> {
    return this.queue.run(() => {
      validateFindDocumentsInput(input);
      return queryDocuments(this.documents.values(), input).map(copyDocument);
    });
  }

  create(input: CreateDocumentInput): Promise<DocumentRecord> {
    return this.queue.run(() => {
      validateCreateDocumentInput(input);
      const documentId = input.documentId ?? randomUUID();
      this.requireCollection(input.teamId, input.collectionId);
      const key = documentKey(input.teamId, input.collectionId, documentId);
      if (this.documents.has(key)) throw new Error("Die Datensatz-ID existiert bereits.");
      const timestamp = new Date();
      const document = documentFrom(input, documentId, 1, timestamp, timestamp);
      this.documents.set(key, document);
      return copyDocument(document);
    });
  }

  update(input: UpdateDocumentInput): Promise<DocumentRecord> {
    return this.queue.run(() => {
      validateUpdateDocumentInput(input);
      const current = this.loadDocument(input);
      if (current === undefined) throw new Error("Der Datensatz wurde nicht gefunden.");
      return this.replaceDocument(input, current);
    });
  }

  upsert(input: UpsertDocumentInput): Promise<DocumentRecord> {
    return this.queue.run(() => {
      validateUpdateDocumentInput(input);
      const current = this.loadDocument(input);
      if (current !== undefined) return this.replaceDocument(input, current);
      this.requireCollection(input.teamId, input.collectionId);
      const timestamp = new Date();
      const document = documentFrom(input, input.documentId, 1, timestamp, timestamp);
      this.documents.set(documentKey(input.teamId, input.collectionId, input.documentId), document);
      return copyDocument(document);
    });
  }

  private replaceDocument(input: UpdateDocumentInput, current: DocumentRecord): DocumentRecord {
    if (input.expectedVersion !== undefined && input.expectedVersion !== current.version) {
      throw new Error("Der Datensatz wurde inzwischen geändert.");
    }
    const updated = documentFrom(input, input.documentId, current.version + 1, current.createdAt, new Date());
    this.documents.set(documentKey(input.teamId, input.collectionId, input.documentId), updated);
    return copyDocument(updated);
  }

  private removeDocuments(input: DeleteDocumentsInput): number {
    const keys = keysToDelete(this.documents, input);
    for (const key of keys) this.documents.delete(key);
    return keys.length;
  }

  private loadDocument(input: UpdateDocumentInput): DocumentRecord | undefined {
    return this.documents.get(documentKey(input.teamId, input.collectionId, input.documentId));
  }

  private collectionByName(input: DocumentCollectionNameInput): DocumentCollection | undefined {
    return collectionNamed(this.collections.values(), input);
  }

  private requireCollection(teamId: string, collectionId: string): void {
    if (!this.collections.has(collectionKey(teamId, collectionId))) {
      throw new Error("Die Datensammlung wurde nicht gefunden.");
    }
  }
}
