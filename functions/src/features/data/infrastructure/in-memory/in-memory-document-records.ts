import {type DocumentCollection} from "../../domain/entities/document-collection.js";
import {cloneDocumentData, type CreateDocumentInput, type DocumentRecord} from "../../domain/entities/document.js";

/** Kopien und Schlüssel des In-Memory-Stores — Rückgaben dürfen den Bestand nie verändern. */
export function documentFrom(
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

export function copyDocument(document: DocumentRecord): DocumentRecord {
  return {...document, data: cloneDocumentData(document.data), createdAt: new Date(document.createdAt), updatedAt: new Date(document.updatedAt)};
}

export function copyOrNull(collection: DocumentCollection | undefined): DocumentCollection | null {
  return collection === undefined ? null : copyCollection(collection);
}

export function copyCollection(collection: DocumentCollection): DocumentCollection {
  return {...collection, createdAt: new Date(collection.createdAt), updatedAt: new Date(collection.updatedAt)};
}

export function collectionKey(teamId: string, collectionId: string): string {
  return `${teamId}\u0000${collectionId}`;
}

export function documentKey(teamId: string, collectionId: string, documentId: string): string {
  return `${collectionKey(teamId, collectionId)}\u0000${documentId}`;
}
