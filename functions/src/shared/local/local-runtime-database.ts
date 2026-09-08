import {loadSqlMigrations} from "./sql-migration-loader.js";
import {SqlMigrationRunner} from "./sql-migration-runner.js";
import {
  SqliteLocalSqlDatabase,
  type SqliteLocalSqlDatabaseOptions,
} from "./sqlite-local-sql-database.js";

export type LocalRuntimeDatabaseOptions = SqliteLocalSqlDatabaseOptions & {
  databasePath: string;
  migrationsDirectory: string;
};

export async function openLocalRuntimeDatabase(
  options: LocalRuntimeDatabaseOptions,
): Promise<SqliteLocalSqlDatabase> {
  const database = new SqliteLocalSqlDatabase(options.databasePath, options);
  try {
    const migrations = await loadSqlMigrations(options.migrationsDirectory);
    await new SqlMigrationRunner(database).run(migrations);
    return database;
  } catch (error) {
    database.close();
    throw error;
  }
}
