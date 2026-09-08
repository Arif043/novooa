import {AsyncLocalStorage} from "node:async_hooks";
import {mkdirSync} from "node:fs";
import {dirname} from "node:path";
import {DatabaseSync} from "node:sqlite";
import {
  type LocalSqlDatabase,
  type SqlParameters,
  type SqlRow,
} from "./local-sql-database.js";

export type SqliteLocalSqlDatabaseOptions = {
  busyTimeoutMs?: number;
};

export class SqliteLocalSqlDatabase implements LocalSqlDatabase {
  private readonly database: DatabaseSync;
  private readonly transactionContext = new AsyncLocalStorage<boolean>();
  private queue: Promise<void> = Promise.resolve();

  constructor(databasePath: string, options: SqliteLocalSqlDatabaseOptions = {}) {
    ensureDirectory(databasePath);
    this.database = new DatabaseSync(databasePath, {
      enableForeignKeyConstraints: true,
      timeout: options.busyTimeoutMs ?? 5000,
    });
    this.database.exec("PRAGMA journal_mode = WAL");
  }

  async get<T extends SqlRow>(sql: string, parameters: SqlParameters = []): Promise<T | null> {
    return this.perform(() => recordFrom<T>(this.database.prepare(sql).get(...parameters)));
  }

  async all<T extends SqlRow>(sql: string, parameters: SqlParameters = []): Promise<T[]> {
    return this.perform(() => recordsFrom<T>(this.database.prepare(sql).all(...parameters)));
  }

  async run(sql: string, parameters: SqlParameters = []): Promise<void> {
    await this.perform(() => {
      this.database.prepare(sql).run(...parameters);
    });
  }

  async transaction<T>(operation: () => Promise<T>): Promise<T> {
    if (this.transactionContext.getStore()) return operation();
    return this.perform(() => this.runTransaction(operation));
  }

  close(): void {
    this.database.close();
  }

  private async runTransaction<T>(operation: () => Promise<T>): Promise<T> {
    this.database.exec("BEGIN IMMEDIATE");
    try {
      const output = await this.transactionContext.run(true, operation);
      this.database.exec("COMMIT");
      return output;
    } catch (error) {
      this.database.exec("ROLLBACK");
      throw error;
    }
  }

  private perform<T>(operation: () => T | Promise<T>): Promise<T> {
    if (this.transactionContext.getStore()) return Promise.resolve().then(operation);
    const completed = this.queue.then(operation, operation);
    this.queue = completed.then(() => undefined, () => undefined);
    return completed;
  }
}

function ensureDirectory(databasePath: string): void {
  if (databasePath === ":memory:") return;
  mkdirSync(dirname(databasePath), {recursive: true});
}

function recordFrom<T extends SqlRow>(row: SqlRow | undefined): T | null {
  return row === undefined ? null : {...row} as T;
}

function recordsFrom<T extends SqlRow>(rows: SqlRow[]): T[] {
  return rows.map((row) => ({...row} as T));
}
