import {readdir, readFile} from "node:fs/promises";
import {join} from "node:path";
import {migrationFromSqlFile} from "./sql-migration-parser.js";
import {type SqlMigration} from "./sql-migration-runner.js";

export async function loadSqlMigrations(migrationsDirectory: string): Promise<SqlMigration[]> {
  const entries = await readdir(migrationsDirectory, {withFileTypes: true});
  const fileNames = entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(".sql"))
    .map((entry) => entry.name)
    .sort();
  const migrations = await Promise.all(fileNames.map((fileName) => loadMigration(migrationsDirectory, fileName)));
  ensureUniqueVersions(migrations);
  return migrations;
}

async function loadMigration(directory: string, fileName: string): Promise<SqlMigration> {
  const content = await readFile(join(directory, fileName), "utf8");
  return migrationFromSqlFile(versionFrom(fileName), content);
}

function versionFrom(fileName: string): string {
  const match = /^(\d+_[a-z0-9_]+)\.sql$/i.exec(fileName);
  if (match) return match[1];
  throw new Error(`Der Migrationsdateiname ${fileName} ist ungültig.`);
}

function ensureUniqueVersions(migrations: readonly SqlMigration[]): void {
  const versions = new Set(migrations.map((migration) => migration.version));
  if (versions.size !== migrations.length) throw new Error("Migrationsversionen müssen eindeutig sein.");
}
