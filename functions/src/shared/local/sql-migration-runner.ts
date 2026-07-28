import {
  type LocalSqlDatabase,
  type SqlRow,
} from "./local-sql-database.js";

export type SqlMigration = {
  version: string;
  statements: readonly string[];
};

type MigrationRow = SqlRow & {
  version: string;
};

export class SqlMigrationRunner {
  constructor(private readonly database: LocalSqlDatabase) {}

  async run(migrations: readonly SqlMigration[]): Promise<string[]> {
    await this.ensureMigrationTable();
    const appliedVersions = await this.appliedVersions();
    const appliedNow: string[] = [];
    for (const migration of orderedMigrations(migrations)) {
      if (appliedVersions.has(migration.version)) continue;
      await this.applyMigration(migration);
      appliedNow.push(migration.version);
    }
    return appliedNow;
  }

  private async ensureMigrationTable(): Promise<void> {
    await this.database.run(
      `CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY,
        applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )`,
    );
  }

  private async appliedVersions(): Promise<Set<string>> {
    const rows = await this.database.all<MigrationRow>(
      "SELECT version FROM schema_migrations",
    );
    return new Set(rows.map((row) => row.version));
  }

  private async applyMigration(migration: SqlMigration): Promise<void> {
    await this.database.transaction(async () => {
      for (const statement of migration.statements) {
        if (statement.trim().length === 0) continue;
        await this.database.run(statement);
      }
      await this.database.run(
        "INSERT OR IGNORE INTO schema_migrations(version) VALUES (?)",
        [migration.version],
      );
    });
  }
}

function orderedMigrations(
  migrations: readonly SqlMigration[],
): readonly SqlMigration[] {
  return [...migrations].sort((left, right) =>
    left.version.localeCompare(right.version),
  );
}
