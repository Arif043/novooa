import {type DocumentRecord, type DocumentValue} from "../entities/document.js";
import {type DocumentSort} from "../entities/document-filter.js";

/** Rang der Wertarten beim Sortieren; fehlende und leere Werte immer zuletzt. */
export const documentSortRanks = {number: 0, text: 1, boolean: 2, structure: 3, missing: 4} as const;

export function documentSortRank(value: DocumentValue | undefined): number {
  if (value === undefined || value === null) return documentSortRanks.missing;
  if (typeof value === "number") return documentSortRanks.number;
  if (typeof value === "string") return documentSortRanks.text;
  if (typeof value === "boolean") return documentSortRanks.boolean;
  return documentSortRanks.structure;
}

/** Ohne Sortierung: zuletzt geändert zuerst, bei Gleichstand nach ID — wie bisher. */
export function compareDocumentsForSort(sort: DocumentSort | undefined) {
  return (left: DocumentRecord, right: DocumentRecord): number =>
    (sort === undefined ? 0 : compareByField(left, right, sort)) ||
    right.updatedAt.getTime() - left.updatedAt.getTime() ||
    compareText(left.id, right.id);
}

function compareByField(left: DocumentRecord, right: DocumentRecord, sort: DocumentSort): number {
  const leftValue = left.data[sort.field];
  const rightValue = right.data[sort.field];
  const rankOrder = documentSortRank(leftValue) - documentSortRank(rightValue);
  if (rankOrder !== 0) return rankOrder;
  const valueOrder = compareSameRank(leftValue, rightValue);
  return sort.direction === "asc" ? valueOrder : -valueOrder;
}

function compareSameRank(left: DocumentValue | undefined, right: DocumentValue | undefined): number {
  if (typeof left === "number" && typeof right === "number") return left - right;
  if (typeof left === "string" && typeof right === "string") return compareText(asciiLower(left), asciiLower(right));
  if (typeof left === "boolean" && typeof right === "boolean") return Number(left) - Number(right);
  if (left === undefined || left === null || right === undefined || right === null) return 0;
  return compareText(asciiLower(JSON.stringify(left)), asciiLower(JSON.stringify(right)));
}

/** Wie SQLite `COLLATE NOCASE`: nur A–Z werden klein, Rest nach Codepunkten. */
function asciiLower(value: string): string {
  return value.replace(/[A-Z]/g, (letter) => letter.toLowerCase());
}

function compareText(left: string, right: string): number {
  return left < right ? -1 : left > right ? 1 : 0;
}
