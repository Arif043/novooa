import {asc, desc, sql, type SQL} from "drizzle-orm";
import {documents} from "../../../../db/schema.js";
import {type DocumentSort} from "../../domain/entities/document-filter.js";
import {documentSortRanks} from "../../domain/services/document-sort-order.js";

/**
 * SQL-Gegenstück zu `compareDocumentsForSort`: erst Rang der Wertart (fehlend zuletzt), dann der
 * Wert, zuletzt Änderungszeit und ID. Der Feldname ist validiert (`isQueryableFieldName`).
 */
export function sqlOrderFor(sort: DocumentSort | undefined): SQL[] {
  const fallback = [desc(documents.updated_at), asc(documents.id)];
  if (sort === undefined) return fallback;
  const path = `$.${sort.field}`;
  const type = sql`json_type(${documents.data_json}, ${path})`;
  const value = sql`json_extract(${documents.data_json}, ${path}) COLLATE NOCASE`;
  const rank = sql`CASE ${type}
    WHEN 'integer' THEN ${documentSortRanks.number} WHEN 'real' THEN ${documentSortRanks.number}
    WHEN 'text' THEN ${documentSortRanks.text}
    WHEN 'true' THEN ${documentSortRanks.boolean} WHEN 'false' THEN ${documentSortRanks.boolean}
    WHEN 'object' THEN ${documentSortRanks.structure} WHEN 'array' THEN ${documentSortRanks.structure}
    ELSE ${documentSortRanks.missing} END`;
  return [asc(rank), sort.direction === "asc" ? asc(value) : desc(value), ...fallback];
}
