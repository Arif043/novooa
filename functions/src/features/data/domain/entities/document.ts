import {
  validateDocumentCollectionId,
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
  if (Array.isArray(value)) return value.forEach((item) => validateValue(item, visited, depth + 1));
  if (!isRecord(value)) throw new Error("Datensatzwerte müssen JSON-kompatibel sein.");
  Object.entries(value).forEach(([key, item]) => {
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
