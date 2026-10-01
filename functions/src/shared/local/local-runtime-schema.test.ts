import {sql} from "drizzle-orm";
import {getTableConfig} from "drizzle-orm/sqlite-core";
import assert from "node:assert/strict";
import {resolve} from "node:path";
import test from "node:test";
import * as schema from "../../db/schema.js";
import {openLocalRuntimeDatabase} from "./local-runtime-database.js";

test("Drizzle defines all migration-managed runtime tables with matching columns and defaults", async (t) => {
  const database = await openLocalRuntimeDatabase({databasePath: ":memory:",
    migrationsDirectory: resolve(__dirname, "../../../drizzle")});
  t.after(() => database.$client.close());
  const tables = Object.values(schema);
  const stored = await database.all<{name: string}>(sql`SELECT name FROM sqlite_master
    WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name != '__drizzle_migrations'`);
  assert.deepEqual(tables.map((table) => getTableConfig(table).name).sort(), stored.map((table) => table.name).sort());
  for (const table of tables) {
    const configuration = getTableConfig(table);
    const columns = await database.all<{name: string; type: string; dflt_value: string | null}>(
      sql`SELECT name, type, dflt_value FROM pragma_table_info(${configuration.name}) ORDER BY cid`);
    assert.deepEqual(configuration.columns.map((column) => column.name), columns.map((column) => column.name), configuration.name);
    for (const column of configuration.columns) {
      const storedColumn = columns.find((entry) => entry.name === column.name)!;
      assert.equal(column.getSQLType().toUpperCase(), storedColumn.type, `${configuration.name}.${column.name}`);
      assert.equal(column.hasDefault, storedColumn.dflt_value !== null || column.primary && column.getSQLType() === "integer");
    }
  }
});
