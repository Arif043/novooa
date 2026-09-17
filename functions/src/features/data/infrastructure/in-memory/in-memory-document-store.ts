import {randomUUID} from "node:crypto";
import {
  type CreateDocumentCollectionInput,
  type DocumentCollection,
  type DocumentCollectionNameInput,
  validateDocumentCollectionInput,
  validateDocumentCollectionNameInput,
} from "../../domain/entities/document-collection.js";
import {
  cloneDocumentData,
  type CreateDocumentInput,
  type DocumentRecord,
  type FindDocumentByIdInput,
  type UpdateDocumentInput,
  type UpsertDocumentInput,
  validateCreateDocumentInput,
  validateFindDocumentByIdInput,
  validateUpdateDocumentInput,
} from "../../domain/entities/document.js";
import {
  isNumericOperator,
  type DocumentFilter,
  type FindDocumentsInput,
  validateFindDocumentsInput,
} from "../../domain/entities/document-filter.js";
import {type DocumentStore} from "../../domain/repositories/document-store.js";

export class InMemoryDocumentStore implements DocumentStore {
  private readonly collections = new Map<string, DocumentCollection>();
  private readonly documents = new Map<string, DocumentRecord>();
  private queue: Promise<void> = Promise.resolve();

  createCollection(input: CreateDocumentCollectionInput): Promise<DocumentCollection> {
    return this.exclusively(() => {
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
    return this.exclusively(() => {
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
    return this.exclusively(() => {
      validateDocumentCollectionNameInput(input);
      return copyOrNull(this.collectionByName(input));
    });
  }

  findOne(input: FindDocumentsInput): Promise<DocumentRecord | null> {
    return this.findMany({...input, limit: 1}).then((documents) => documents[0] ?? null);
  }

  findById(input: FindDocumentByIdInput): Promise<DocumentRecord | null> {
    return this.exclusively(() => {
      validateFindDocumentByIdInput(input);
      const document = this.documents.get(documentKey(
        input.teamId, input.collectionId, input.documentId,
      ));
      return document === undefined ? null : copyDocument(document);
    });
  }

  findMany(input: FindDocumentsInput): Promise<DocumentRecord[]> {
    return this.exclusively(() => {
      validateFindDocumentsInput(input);
      return [...this.documents.values()]
        .filter((document) => isMatchingDocument(document, input))
        .sort(compareDocuments)
        .slice(0, input.limit ?? 100)
        .map(copyDocument);
    });
  }

  create(input: CreateDocumentInput): Promise<DocumentRecord> {
    return this.exclusively(() => {
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
    return this.exclusively(() => {
      validateUpdateDocumentInput(input);
      const current = this.loadDocument(input);
      if (current === undefined) throw new Error("Der Datensatz wurde nicht gefunden.");
      return this.replaceDocument(input, current);
    });
  }

  upsert(input: UpsertDocumentInput): Promise<DocumentRecord> {
    return this.exclusively(() => {
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

  private loadDocument(input: UpdateDocumentInput): DocumentRecord | undefined {
    return this.documents.get(documentKey(input.teamId, input.collectionId, input.documentId));
  }

  private collectionByName(input: DocumentCollectionNameInput): DocumentCollection | undefined {
    return [...this.collections.values()].find((collection) =>
      collection.teamId === input.teamId && collection.displayName === input.displayName,
    );
  }

  private requireCollection(teamId: string, collectionId: string): void {
    if (!this.collections.has(collectionKey(teamId, collectionId))) {
      throw new Error("Die Datensammlung wurde nicht gefunden.");
    }
  }

  private exclusively<T>(operation: () => T): Promise<T> {
    const completed = this.queue.then(operation, operation);
    this.queue = completed.then(() => undefined, () => undefined);
    return completed;
  }
}

function isMatchingDocument(document: DocumentRecord, input: FindDocumentsInput): boolean {
  return document.teamId === input.teamId && document.collectionId === input.collectionId &&
    (input.filters ?? []).every((filter) => isMatchingFilter(document, filter));
}

function isMatchingFilter(document: DocumentRecord, filter: DocumentFilter): boolean {
  const value = document.data[filter.field];
  if (filter.operator === "contains") return typeof value === "string" && value.includes(filter.value as string);
  if (isNumericOperator(filter.operator)) {
    return typeof value === "number" && typeof filter.value === "number" &&
      numericComparison(value, filter.operator, filter.value);
  }
  if (value === undefined || typeof value === "object") return false;
  return filter.operator === "equals" ? value === filter.value : value !== filter.value;
}

function numericComparison(
  value: number,
  operator: DocumentFilter["operator"],
  expected: number,
): boolean {
  switch (operator) {
    case "greaterThan": return value > expected;
    case "greaterThanOrEqual": return value >= expected;
    case "lessThan": return value < expected;
    case "lessThanOrEqual": return value <= expected;
    default: throw new Error("Der Datenfilter ist kein numerischer Vergleich.");
  }
}

function documentFrom(
  input: CreateDocumentInput,
  id: string,
  version: number,
  createdAt: Date,
  updatedAt: Date,
): DocumentRecord {
  return {
    id, teamId: input.teamId, collectionId: input.collectionId,
    data: cloneDocumentData(input.data), version,
    createdAt: new Date(createdAt), updatedAt: new Date(updatedAt),
  };
}

function copyDocument(document: DocumentRecord): DocumentRecord {
  return {...document, data: cloneDocumentData(document.data), createdAt: new Date(document.createdAt), updatedAt: new Date(document.updatedAt)};
}

function copyOrNull(collection: DocumentCollection | undefined): DocumentCollection | null {
  return collection === undefined ? null : copyCollection(collection);
}

function copyCollection(collection: DocumentCollection): DocumentCollection {
  return {...collection, createdAt: new Date(collection.createdAt), updatedAt: new Date(collection.updatedAt)};
}

function compareDocuments(left: DocumentRecord, right: DocumentRecord): number {
  return right.updatedAt.getTime() - left.updatedAt.getTime() || left.id.localeCompare(right.id);
}

function collectionKey(teamId: string, collectionId: string): string {
  return `${teamId}\u0000${collectionId}`;
}

function documentKey(teamId: string, collectionId: string, documentId: string): string {
  return `${collectionKey(teamId, collectionId)}\u0000${documentId}`;
}
