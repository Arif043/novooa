import {type DocumentData, type DocumentValue, maximumDocumentsPerCreate, validateDocumentData} from "../entities/document.js";
import {parseCsv, writeCsv} from "./csv-table.js";
import {normalizeFieldNames, type RenamedField} from "./document-field-names.js";

export const documentTableFormats = ["csv", "json"] as const;

export type DocumentTableFormat = (typeof documentTableFormats)[number];

/** Größte Importdatei; größere Anfragen weist die Route vorher ab. */
export const maximumImportBytes = 5 * 1024 * 1024;

export type DocumentImport = {
  items: DocumentData[];
  /** Alle Feldnamen der Datei nach der Normalisierung, in Reihenfolge des ersten Auftretens. */
  fields: string[];
  renamed: RenamedField[];
  /** Meldungen mit Zeile oder Eintrag; mit Meldungen wird nichts übernommen. */
  issues: string[];
};

export function exportDocuments(format: DocumentTableFormat, documents: readonly DocumentData[]): string {
  if (format === "json") return JSON.stringify(documents, null, 2) + "\n";
  const header = [...new Set(documents.flatMap((document) => Object.keys(document)))].sort();
  return writeCsv(header, documents.map((document) => header.map((field) => csvCell(document[field]))));
}

export function parseDocumentImport(format: DocumentTableFormat, content: string): DocumentImport {
  try {
    return format === "csv" ? csvImport(content) : jsonImport(content);
  } catch (error) {
    return {items: [], fields: [], renamed: [], issues: [error instanceof Error ? error.message : String(error)]};
  }
}

function csvImport(content: string): DocumentImport {
  const [header, ...records] = parseCsv(content);
  if (header === undefined) return {items: [], fields: [], renamed: [], issues: ["Die Datei enthält keine Kopfzeile."]};
  const {fields, renamed} = normalizeFieldNames(header.cells);
  const issues = tooMany(records.length);
  const items = records.slice(0, maximumDocumentsPerCreate).map((record) => {
    if (record.cells.slice(fields.length).some((cell) => cell.trim() !== "")) {
      issues.push(`Zeile ${record.line}: mehr Werte als Spalten in der Kopfzeile.`);
    }
    const data: DocumentData = Object.fromEntries(fields.flatMap((field, index): Array<[string, DocumentValue]> => {
      const cell = record.cells[index] ?? "";
      return cell.trim() === "" ? [] : [[field, inferredValue(cell)]];
    }));
    return data;
  });
  return {items, fields, renamed, issues};
}

function jsonImport(content: string): DocumentImport {
  const parsed = parseJson(content);
  if (!Array.isArray(parsed)) throw new Error("Die JSON-Datei muss eine Liste von Objekten enthalten.");
  const issues = tooMany(parsed.length);
  const entries = parsed.slice(0, maximumDocumentsPerCreate);
  const keys = [...new Set(entries.flatMap((entry) => isObject(entry) ? Object.keys(entry) : []))];
  const {fields, renamed} = normalizeFieldNames(keys);
  const fieldFor = new Map(keys.map((key, index) => [key, fields[index]]));
  const items = entries.flatMap((entry, index): DocumentData[] => {
    if (!isObject(entry)) {
      issues.push(`Eintrag ${index + 1}: ist kein Objekt.`);
      return [];
    }
    const data = Object.fromEntries(Object.entries(entry).map(([key, value]) => [fieldFor.get(key)!, value])) as DocumentData;
    return validEntry(data, index, issues) ? [data] : [];
  });
  return {items, fields, renamed, issues};
}

function validEntry(data: DocumentData, index: number, issues: string[]): boolean {
  try {
    validateDocumentData(data);
    return true;
  } catch (error) {
    issues.push(`Eintrag ${index + 1}: ${error instanceof Error ? error.message : String(error)}`);
    return false;
  }
}

function parseJson(content: string): unknown {
  try {
    return JSON.parse(content.replace(/^\uFEFF/, "")) as unknown;
  } catch {
    throw new Error("Die Datei enthält kein gültiges JSON.");
  }
}

function tooMany(count: number): string[] {
  return count > maximumDocumentsPerCreate
    ? [`Die Datei enthält ${count} Datensätze; höchstens ${maximumDocumentsPerCreate} lassen sich auf einmal importieren.`]
    : [];
}

/**
 * Wie im Editor: `true`/`false` und Zahlen werden erkannt, sonst bleibt Text. Zahlen mit
 * führender Null (Postleitzahlen, Kundennummern) bleiben Text, damit die Null nicht verloren geht.
 */
export function inferredValue(cell: string): DocumentValue {
  const trimmed = cell.trim();
  if (trimmed === "true") return true;
  if (trimmed === "false") return false;
  if (/^-?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?$/.test(trimmed)) {
    const number = Number(trimmed);
    if (Number.isFinite(number)) return number;
  }
  return cell;
}

function csvCell(value: DocumentValue | undefined): string {
  if (value === undefined || value === null) return "";
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
