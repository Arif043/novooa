import {
  type CreateDocumentCollectionInput,
  type DocumentCollection,
  type DocumentCollectionNameInput,
  type DocumentCollectionRef,
  type RenameDocumentCollectionInput,
} from "../entities/document-collection.js";
import {
  type CreateDocumentInput,
  type CreateDocumentsInput,
  type DeleteDocumentsInput,
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
  listCollections(teamId: string): Promise<DocumentCollection[]>;
  /** `null`, wenn die Sammlung fehlt; wirft `DocumentCollectionNameTakenError` bei belegtem Namen. */
  renameCollection(input: RenameDocumentCollectionInput): Promise<DocumentCollection | null>;
  /** Löscht die Sammlung samt Datensätzen; `false`, wenn sie fehlt. */
  deleteCollection(input: DocumentCollectionRef): Promise<boolean>;
  countDocuments(input: FindDocumentsInput): Promise<number>;
  findById(input: FindDocumentByIdInput): Promise<DocumentRecord | null>;
  findOne(input: FindDocumentsInput): Promise<DocumentRecord | null>;
  findMany(input: FindDocumentsInput): Promise<DocumentRecord[]>;
  create(input: CreateDocumentInput): Promise<DocumentRecord>;
  /** Legt alle Datensätze in einer Transaktion an — alle oder keiner. Liefert die Anzahl. */
  createMany(input: CreateDocumentsInput): Promise<number>;
  update(input: UpdateDocumentInput): Promise<DocumentRecord>;
  delete(input: FindDocumentByIdInput): Promise<boolean>;
  /** Löscht die genannten oder — ohne IDs — alle Datensätze der Sammlung; liefert die Anzahl. */
  deleteDocuments(input: DeleteDocumentsInput): Promise<number>;
  upsert(input: UpsertDocumentInput): Promise<DocumentRecord>;
}
