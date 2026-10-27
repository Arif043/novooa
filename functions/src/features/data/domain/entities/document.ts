import {
  type DocumentCollectionRef,
  validateDocumentCollectionId,
  validateDocumentCollectionRef,
  validateTeamId,
} from "./document-collection.js";

export type DocumentScalar = string | number | boolean | null;
export type DocumentValue = DocumentScalar | DocumentData | readonly DocumentValue[];

export interface DocumentData {
  readonly [field: string]: DocumentValue;
}

export type DocumentRecord = {
  id: string;
  teamId: string;
  collectionId: string;
  data: DocumentData;
  version: number;
  createdAt: Date;
  updatedAt: Date;
};

export type CreateDocumentInput = {
  teamId: string;
  collectionId: string;
  documentId?: string;
  data: DocumentData;
};

export type FindDocumentByIdInput = {
  teamId: string;
  collectionId: string;
  documentId: string;
};

export type UpdateDocumentInput = {
  teamId: string;
  collectionId: string;
  documentId: string;
  data: DocumentData;
  expectedVersion?: number;
};

export type UpsertDocumentInput = UpdateDocumentInput;

/** Höchstzahl gezielt zu löschender Datensätze je Aufruf (eine Seite der Ansicht). */
export const maximumDocumentIdsPerDelete = 500;

/** Höchstzahl der Datensätze, die ein Import auf einmal anlegt. */
export const maximumDocumentsPerCreate = 5000;

/** Ohne `documentIds` werden alle Datensätze der Sammlung gelöscht. */
export type DeleteDocumentsInput = DocumentCollectionRef & {documentIds?: readonly string[]};

export type CreateDocumentsInput = DocumentCollectionRef & {items: readonly DocumentData[]};

export function validateDeleteDocumentsInput(input: DeleteDocumentsInput): void {
  validateDocumentCollectionRef(input);
  if (input.documentIds === undefined) return;
  if (input.documentIds.length > maximumDocumentIdsPerDelete) {
    throw new Error(`Höchstens ${maximumDocumentIdsPerDelete} Datensätze auf einmal löschen.`);
  }
  for (const documentId of input.documentIds) validateDocumentId(documentId);
}

export function validateCreateDocumentsInput(input: CreateDocumentsInput): void {
  validateDocumentCollectionRef(input);
  if (input.items.length > maximumDocumentsPerCreate) {
    throw new Error(`Höchstens ${maximumDocumentsPerCreate} Datensätze auf einmal anlegen.`);
  }
  for (const data of input.items) validateDocumentData(data);
}

export function validateCreateDocumentInput(input: CreateDocumentInput): void {
  validateDocumentTarget(input.teamId, input.collectionId, input.documentId);
  validateDocumentData(input.data);
}

export function validateFindDocumentByIdInput(input: FindDocumentByIdInput): void {
  validateDocumentTarget(input.teamId, input.collectionId, input.documentId);
}

export function validateUpdateDocumentInput(input: UpdateDocumentInput): void {
  validateDocumentTarget(input.teamId, input.collectionId, input.documentId);
  validateDocumentData(input.data);
  if (input.expectedVersion !== undefined && (!Number.isSafeInteger(input.expectedVersion) || input.expectedVersion < 1)) {
    throw new Error("Die erwartete Dokumentversion ist ungültig.");
  }
}

export function validateDocumentData(data: DocumentData): void {
  if (!isRecord(data)) throw new Error("Ein Datensatz muss ein Objekt sein.");
  validateValue(data, new Set<object>(), 0);
}

export function cloneDocumentData(data: DocumentData): DocumentData {
  validateDocumentData(data);
  return JSON.parse(JSON.stringify(data)) as DocumentData;
}

function validateDocumentTarget(teamId: string, collectionId: string, documentId?: string): void {
  validateTeamId(teamId);
  validateDocumentCollectionId(collectionId);
  if (documentId !== undefined) validateDocumentId(documentId);
}

function validateDocumentId(documentId: string): void {
  if (!/^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/.test(documentId)) {
    throw new Error("Die Datensatz-ID ist ungültig.");
  }
}

function validateValue(value: DocumentValue, visited: Set<object>, depth: number): void {
  if (depth > 20) throw new Error("Ein Datensatz darf höchstens 20 Ebenen verschachtelt sein.");
  if (value === null || typeof value === "string" || typeof value === "boolean") return;
  if (typeof value === "number") return validateNumber(value);
  if (typeof value !== "object") throw new Error("Datensatzwerte müssen JSON-kompatibel sein.");
  if (visited.has(value)) throw new Error("Datensätze dürfen keine zyklischen Werte enthalten.");
  visited.add(value);
  // `Array.isArray` verengt auf `any[]`; die Elemente sind Datensatzwerte.
  if (Array.isArray(value)) return (value as readonly DocumentValue[]).forEach((item) => validateValue(item, visited, depth + 1));
  if (!isRecord(value)) throw new Error("Datensatzwerte müssen JSON-kompatibel sein.");
  Object.entries<DocumentValue>(value).forEach(([key, item]) => {
    if (!/^[a-zA-Z_][a-zA-Z0-9_]{0,63}$/.test(key)) {
      throw new Error("Datenfelder dürfen nur Buchstaben, Zahlen und Unterstriche enthalten.");
    }
    validateValue(item, visited, depth + 1);
  });
}

function validateNumber(value: number): void {
  if (!Number.isFinite(value)) throw new Error("Datensatzwerte müssen endliche Zahlen sein.");
}

function isRecord(value: unknown): value is Record<string, DocumentValue> {
  return typeof value === "object" && value !== null && !Array.isArray(value) &&
    Object.getPrototypeOf(value) === Object.prototype;
}
