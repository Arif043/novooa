import {createClient, type Client} from "@libsql/client";
import {drizzle, type LibSQLDatabase} from "drizzle-orm/libsql";
import {pathToFileURL} from "node:url";
import * as schema from "./schema.js";

export type RuntimeDatabase = LibSQLDatabase<typeof schema> & {$client: Client};
export type RuntimeTransaction = Parameters<Parameters<RuntimeDatabase["transaction"]>[0]>[0];
export type RuntimeExecutor = RuntimeDatabase | RuntimeTransaction;

export function connectRuntimeDatabase(databasePath: string): RuntimeDatabase {
  const client = createClient({url: databasePath === ":memory:" ? "file::memory:" : pathToFileURL(databasePath).href});
  return drizzle({client, schema});
}
