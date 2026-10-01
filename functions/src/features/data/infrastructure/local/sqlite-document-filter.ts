import {and, eq, gt, gte, inArray, lt, lte, ne, sql, type SQL} from "drizzle-orm";
import {documents} from "../../../../db/schema.js";
import {isNumericOperator, type DocumentFilter, type DocumentFilterValue} from "../../domain/entities/document-filter.js";

export function sqlFilterFor(filter: DocumentFilter): SQL {
  const path = `$.${filter.field}`;
  const value = sql`json_extract(${documents.data_json}, ${path})`;
  const type = sql`json_type(${documents.data_json}, ${path})`;
  if (filter.operator === "contains") {
    if (typeof filter.value !== "string") throw new Error("Der Datenfilter enthält keinen Textwert.");
    return and(eq(type, "text"), gt(sql`instr(${value}, ${filter.value})`, 0))!;
  }
  if (isNumericOperator(filter.operator)) {
    if (typeof filter.value !== "number") throw new Error("Der Datenfilter enthält keine Zahl.");
    return and(inArray(type, ["integer", "real"]), numericComparison(sql`CAST(${value} AS REAL)`, filter))!;
  }
  const typeClause = typeof filter.value === "number" ? inArray(type, ["integer", "real"]) : eq(type, jsonTypeFor(filter.value));
  const expected = typeof filter.value === "boolean" ? Number(filter.value) : filter.value;
  return and(typeClause, filter.operator === "equals" ? eq(value, expected) : ne(value, expected))!;
}

function numericComparison(value: SQL, filter: DocumentFilter): SQL {
  switch (filter.operator) {
    case "greaterThan": return gt(value, filter.value);
    case "greaterThanOrEqual": return gte(value, filter.value);
    case "lessThan": return lt(value, filter.value);
    case "lessThanOrEqual": return lte(value, filter.value);
    default: throw new Error("Der Datenfilter ist kein numerischer Vergleich.");
  }
}

function jsonTypeFor(value: DocumentFilterValue): string {
  if (typeof value === "string") return "text";
  if (typeof value === "boolean") return value ? "true" : "false";
  return "number";
}
