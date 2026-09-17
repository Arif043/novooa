import {
  type CreateDocumentCollectionInput,
  type DocumentCollection,
  type DocumentCollectionNameInput,
} from "../domain/entities/document-collection.js";
import {
  type CreateDocumentInput,
  type DocumentRecord,
  type FindDocumentByIdInput,
  type UpdateDocumentInput,
  type UpsertDocumentInput,
} from "../domain/entities/document.js";
import {type FindDocumentsInput} from "../domain/entities/document-filter.js";
import {type DocumentStore} from "../domain/repositories/document-store.js";

export class UnavailableDocumentStore implements DocumentStore {
  createCollection(_input: CreateDocumentCollectionInput): Promise<DocumentCollection> {
    return unavailable();
  }

  ensureCollection(_input: DocumentCollectionNameInput): Promise<DocumentCollection> {
    return unavailable();
  }

  findCollectionByName(_input: DocumentCollectionNameInput): Promise<DocumentCollection | null> {
    return unavailable();
  }

  findById(_input: FindDocumentByIdInput): Promise<DocumentRecord | null> {
    return unavailable();
  }

  findOne(_input: FindDocumentsInput): Promise<DocumentRecord | null> {
    return unavailable();
  }

  findMany(_input: FindDocumentsInput): Promise<DocumentRecord[]> {
    return unavailable();
  }

  create(_input: CreateDocumentInput): Promise<DocumentRecord> {
    return unavailable();
  }

  update(_input: UpdateDocumentInput): Promise<DocumentRecord> {
    return unavailable();
  }

  upsert(_input: UpsertDocumentInput): Promise<DocumentRecord> {
    return unavailable();
  }
}

function unavailable<T>(): Promise<T> {
  return Promise.reject(new Error("Die Datenablage ist in dieser Runtime noch nicht verfügbar."));
}
