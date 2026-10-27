import {validateDocumentCollectionId, validateTeamId} from "./document-collection.js";

export const documentFilterOperators = [
  "equals",
  "notEquals",
  "greaterThan",
  "greaterThanOrEqual",
  "lessThan",
  "lessThanOrEqual",
  "contains",
] as const;

export type DocumentFilterOperator = (typeof documentFilterOperators)[number];
export type DocumentFilterValue = string | number | boolean;

export type DocumentFilter = {
  field: string;
  operator: DocumentFilterOperator;
  value: DocumentFilterValue;
};

export const documentSortDirections = ["asc", "desc"] as const;

export type DocumentSortDirection = (typeof documentSortDirections)[number];

/**
 * Sortiert nach einem sichtbaren Feld. Reihenfolge der Wertarten: Zahlen, Text, Wahrheitswerte,
 * Strukturen; fehlende und leere Werte stehen immer am Ende. Text ohne Unterschied von
 * Groß- und Kleinschreibung (ASCII).
 */
export type DocumentSort = {
  field: string;
  direction: DocumentSortDirection;
};

export type FindDocumentsInput = {
  teamId: string;
  collectionId: string;
  filters?: readonly DocumentFilter[];
  sort?: DocumentSort;
  limit?: number;
  offset?: number;
};

export function validateFindDocumentsInput(input: FindDocumentsInput): void {
  validateTeamId(input.teamId);
  validateDocumentCollectionId(input.collectionId);
  validateLimit(input.limit);
  validateOffset(input.offset);
  for (const filter of input.filters ?? []) validateDocumentFilter(filter);
  if (input.sort !== undefined) validateDocumentSort(input.sort);
}

/** Feldnamen, nach denen gefiltert und sortiert werden darf — keine Pfade, kein SQL. */
export function isQueryableFieldName(field: string): boolean {
  return /^[a-zA-Z_][a-zA-Z0-9_]{0,63}$/.test(field);
}

export function validateDocumentFilter(filter: DocumentFilter): void {
  validateFieldName(filter.field);
  if (!documentFilterOperators.includes(filter.operator)) {
    throw new Error("Der Datenfilter verwendet keinen unterstützten Operator.");
  }
  if (!isFilterValue(filter.value)) throw new Error("Der Wert des Datenfilters ist ungültig.");
  validateOperatorValue(filter);
}

function validateDocumentSort(sort: DocumentSort): void {
  validateFieldName(sort.field);
  if (!documentSortDirections.includes(sort.direction)) {
    throw new Error("Die Sortierrichtung ist ungültig.");
  }
}

function validateFieldName(field: string): void {
  if (!isQueryableFieldName(field)) {
    throw new Error("Datenfelder dürfen nur Buchstaben, Zahlen und Unterstriche enthalten.");
  }
}

function validateOffset(offset: number | undefined): void {
  if (offset === undefined) return;
  if (!Number.isSafeInteger(offset) || offset < 0) throw new Error("Der Versatz der Datensätze ist ungültig.");
}

function validateLimit(limit: number | undefined): void {
  if (limit === undefined) return;
  if (!Number.isSafeInteger(limit) || limit < 1 || limit > 500) {
    throw new Error("Die Anzahl der Datensätze muss zwischen 1 und 500 liegen.");
  }
}

function isFilterValue(value: unknown): value is DocumentFilterValue {
  return typeof value === "string" || typeof value === "boolean" ||
    (typeof value === "number" && Number.isFinite(value));
}

function validateOperatorValue(filter: DocumentFilter): void {
  if (filter.operator === "contains" && typeof filter.value !== "string") {
    throw new Error("Der Operator enthält erwartet einen Textwert.");
  }
  if (isNumericOperator(filter.operator) && typeof filter.value !== "number") {
    throw new Error("Numerische Datenfilter erwarten eine Zahl.");
  }
}

export function isNumericOperator(operator: DocumentFilterOperator): boolean {
  return operator === "greaterThan" || operator === "greaterThanOrEqual" ||
    operator === "lessThan" || operator === "lessThanOrEqual";
}
