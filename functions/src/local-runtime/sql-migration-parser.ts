import {type SqlMigration} from "./sql-migration-runner.js";

export function migrationFromSqlFile(
  version: string,
  sql: string,
): SqlMigration {
  return {
    version,
    statements: statementsFromSql(sql),
  };
}

export function statementsFromSql(sql: string): string[] {
  return sql
    .split(";")
    .map((statement) => statement.trim())
    .filter((statement) => statement.length > 0 && !isPragma(statement));
}

function isPragma(statement: string): boolean {
  return statement.toUpperCase().startsWith("PRAGMA ");
}
