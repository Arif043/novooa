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

export type FindDocumentsInput = {
  teamId: string;
  collectionId: string;
  filters?: readonly DocumentFilter[];
  limit?: number;
};

export function validateFindDocumentsInput(input: FindDocumentsInput): void {
  validateTeamId(input.teamId);
  validateDocumentCollectionId(input.collectionId);
  validateLimit(input.limit);
  for (const filter of input.filters ?? []) validateDocumentFilter(filter);
}

export function validateDocumentFilter(filter: DocumentFilter): void {
  if (!/^[a-zA-Z_][a-zA-Z0-9_]{0,63}$/.test(filter.field)) {
    throw new Error("Datenfelder dürfen nur Buchstaben, Zahlen und Unterstriche enthalten.");
  }
  if (!documentFilterOperators.includes(filter.operator)) {
    throw new Error("Der Datenfilter verwendet keinen unterstützten Operator.");
  }
  if (!isFilterValue(filter.value)) throw new Error("Der Wert des Datenfilters ist ungültig.");
  validateOperatorValue(filter);
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
