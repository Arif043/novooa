import {type WorkflowTable} from "../entities/workflow-value.js";

/** Strukturelle Erkennung eines `WorkflowTable`-Werts, nachdem der
 * Template-Resolver seine `NodeOutputValue`-Typkennung bereits abgestreift
 * hat (`resolveValue` liefert nur noch `unknown`) — dasselbe Muster wie
 * `isMediaReference` im Template-Resolver, nur für Tabellen statt
 * Dateireferenzen. */
export function isWorkflowTable(value: unknown): value is WorkflowTable {
  if (typeof value !== "object" || value === null) return false;
  const candidate = value as Record<string, unknown>;
  return Array.isArray(candidate.columns) &&
    candidate.columns.every((column) => typeof column === "string") &&
    Array.isArray(candidate.rows) &&
    candidate.rows.every((row) => Array.isArray(row));
}
