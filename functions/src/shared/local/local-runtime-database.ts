import {sql} from "drizzle-orm";
import {migrate} from "drizzle-orm/libsql/migrator";
import {mkdir} from "node:fs/promises";
import {dirname} from "node:path";
import {connectRuntimeDatabase, type RuntimeDatabase} from "../../db/database.js";

export type LocalRuntimeDatabaseOptions = {databasePath: string; migrationsDirectory: string};

export async function openLocalRuntimeDatabase(options: LocalRuntimeDatabaseOptions): Promise<RuntimeDatabase> {
  await mkdir(dirname(options.databasePath), {recursive: true});
  const database = connectRuntimeDatabase(options.databasePath);
  try {
    await database.run(sql`PRAGMA foreign_keys = ON`);
    await database.run(sql`PRAGMA busy_timeout = 5000`);
    await database.run(sql`PRAGMA journal_mode = WAL`);
    await migrate(database, {migrationsFolder: options.migrationsDirectory});
    return database;
  } catch (error) {
    database.$client.close();
    throw error;
  }
}
