import {
  type CreateDocumentCollectionInput,
  type DocumentCollection,
  type DocumentCollectionNameInput,
} from "../entities/document-collection.js";
import {
  type CreateDocumentInput,
  type DocumentRecord,
  type FindDocumentByIdInput,
  type UpdateDocumentInput,
  type UpsertDocumentInput,
} from "../entities/document.js";
import {type FindDocumentsInput} from "../entities/document-filter.js";

export interface DocumentStore {
  createCollection(input: CreateDocumentCollectionInput): Promise<DocumentCollection>;
  ensureCollection(input: DocumentCollectionNameInput): Promise<DocumentCollection>;
  findCollectionByName(input: DocumentCollectionNameInput): Promise<DocumentCollection | null>;
  findById(input: FindDocumentByIdInput): Promise<DocumentRecord | null>;
  findOne(input: FindDocumentsInput): Promise<DocumentRecord | null>;
  findMany(input: FindDocumentsInput): Promise<DocumentRecord[]>;
  create(input: CreateDocumentInput): Promise<DocumentRecord>;
  update(input: UpdateDocumentInput): Promise<DocumentRecord>;
  upsert(input: UpsertDocumentInput): Promise<DocumentRecord>;
}
