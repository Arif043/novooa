import {type DocumentCollection, type DocumentCollectionNameInput} from "../../domain/entities/document-collection.js";
import {type DeleteDocumentsInput, type DocumentRecord} from "../../domain/entities/document.js";
import {
  isNumericOperator,
  type DocumentFilter,
  type FindDocumentsInput,
} from "../../domain/entities/document-filter.js";
import {compareDocumentsForSort} from "../../domain/services/document-sort-order.js";

/** Filtert, sortiert und blättert wie der SQLite-Store — Grundlage des Vertragstests. */
export function queryDocuments(documents: Iterable<DocumentRecord>, input: FindDocumentsInput): DocumentRecord[] {
  const offset = input.offset ?? 0;
  return [...documents]
    .filter((document) => isMatchingDocument(document, input))
    .sort(compareDocumentsForSort(input.sort))
    .slice(offset, offset + (input.limit ?? 100));
}

export function collectionNamed(
  collections: Iterable<DocumentCollection>, input: DocumentCollectionNameInput,
): DocumentCollection | undefined {
  return [...collections].find((collection) =>
    collection.teamId === input.teamId && collection.displayName === input.displayName);
}

/** Schlüssel der zu löschenden Datensätze: genannte IDs oder — ohne IDs — die ganze Sammlung. */
export function keysToDelete(documents: Map<string, DocumentRecord>, input: DeleteDocumentsInput): string[] {
  const wanted = input.documentIds === undefined ? undefined : new Set(input.documentIds);
  return [...documents].filter(([, document]) =>
    document.teamId === input.teamId && document.collectionId === input.collectionId &&
    (wanted === undefined || wanted.has(document.id))).map(([key]) => key);
}

export function isMatchingDocument(document: DocumentRecord, input: FindDocumentsInput): boolean {
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

