import writeExcelFile, {type Cell, type Row, type SheetData} from "write-excel-file/node";
import {type WorkflowTable} from "../../domain/entities/workflow-value.js";

/** Serialisiert einen `WorkflowTable`-Wert als XLSX-Datei-Bytes — reiner
 * Adapter auf `write-excel-file`, analog zum Dart-seitigen
 * `XlsxSpreadsheetParser` in `lib/features/files/infrastructure/parsers/`,
 * nur in der Schreibrichtung. */
export async function xlsxBufferFor(table: WorkflowTable): Promise<Uint8Array> {
  const sheetData: SheetData = [headerRowFor(table.columns), ...table.rows.map(rowCellsFor)];
  const buffer = await writeExcelFile(sheetData).toBuffer();
  return new Uint8Array(buffer);
}

function headerRowFor(columns: string[]): Row {
  return columns;
}

function rowCellsFor(row: unknown[]): Row {
  return row.map(cellFor);
}

function cellFor(value: unknown): Cell {
  if (value === null || value === undefined) return null;
  if (value instanceof Date) return value;
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
    return value;
  }
  return JSON.stringify(value);
}
