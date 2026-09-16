import {
  isNumericOperator,
  type DocumentFilter,
  type DocumentFilterValue,
} from "../../domain/entities/document-filter.js";
import {type SqlParameters} from "../../../../shared/local/local-sql-database.js";

export type SqlDocumentFilter = {
  sql: string;
  parameters: SqlParameters;
};

export function sqlFilterFor(filter: DocumentFilter): SqlDocumentFilter {
  const path = `$.${filter.field}`;
  if (filter.operator === "contains") return textContainsFilter(path, filter.value);
  if (isNumericOperator(filter.operator)) return numericFilter(path, filter);
  return equalityFilter(path, filter);
}

function textContainsFilter(path: string, value: DocumentFilterValue): SqlDocumentFilter {
  if (typeof value !== "string") throw new Error("Der Datenfilter enthält keinen Textwert.");
  return {
    sql: "json_type(data_json, ?) = 'text' AND instr(json_extract(data_json, ?), ?) > 0",
    parameters: [path, path, value],
  };
}

function numericFilter(path: string, filter: DocumentFilter): SqlDocumentFilter {
  if (typeof filter.value !== "number") throw new Error("Der Datenfilter enthält keine Zahl.");
  return {
    sql: `json_type(data_json, ?) IN ('integer', 'real') AND CAST(json_extract(data_json, ?) AS REAL) ${comparisonFor(filter.operator)} ?`,
    parameters: [path, path, filter.value],
  };
}

function equalityFilter(path: string, filter: DocumentFilter): SqlDocumentFilter {
  const type = jsonTypeFor(filter.value);
  const operator = filter.operator === "equals" ? "=" : "!=";
  const typeClause = typeof filter.value === "number"
    ? "json_type(data_json, ?) IN ('integer', 'real')"
    : "json_type(data_json, ?) = ?";
  const parameters = typeof filter.value === "number"
    ? [path, path, sqlValueFor(filter.value)]
    : [path, type, path, sqlValueFor(filter.value)];
  return {
    sql: `${typeClause} AND json_extract(data_json, ?) ${operator} ?`,
    parameters,
  };
}

function comparisonFor(operator: DocumentFilter["operator"]): string {
  switch (operator) {
    case "greaterThan": return ">";
    case "greaterThanOrEqual": return ">=";
    case "lessThan": return "<";
    case "lessThanOrEqual": return "<=";
    default: throw new Error("Der Datenfilter ist kein numerischer Vergleich.");
  }
}

function jsonTypeFor(value: DocumentFilterValue): string {
  if (typeof value === "string") return "text";
  if (typeof value === "boolean") return value ? "true" : "false";
  return "number";
}

function sqlValueFor(value: DocumentFilterValue): string | number {
  return typeof value === "boolean" ? Number(value) : value;
}
