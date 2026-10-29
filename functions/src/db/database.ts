import {createClient, type Client} from "@libsql/client";
import {drizzle, type LibSQLDatabase} from "drizzle-orm/libsql";
import {pathToFileURL} from "node:url";
import * as schema from "./schema.js";
import {serializedLibsqlClient} from "./serialized-libsql-client.js";

/**
 * Die SQLite-Datenbank der Runtime über Drizzle, typisiert mit unserem Schema. `$client` ist der
 * rohe libSQL-Client — nur für Prozessdinge wie `database.$client.close()` beim Herunterfahren.
 */
export type RuntimeDatabase = LibSQLDatabase<typeof schema> & {$client: Client};

/**
 * Das `tx` in `database.transaction(async (tx) => …)`. Aus der Signatur abgeleitet statt von Hand
 * benannt, damit der Typ bei Schema- oder Drizzle-Änderungen von selbst stimmt.
 */
export type RuntimeTransaction = Parameters<Parameters<RuntimeDatabase["transaction"]>[0]>[0];

/**
 * Alles, worauf sich SQL ausführen lässt: die Datenbank oder eine offene Transaktion. Stores nehmen
 * diesen Typ, damit derselbe Code allein läuft oder Teil einer umgebenden Transaktion wird
 * (`new SQLiteDocumentCollections(tx)`) — dann gilt alles oder nichts.
 */
export type RuntimeExecutor = RuntimeDatabase | RuntimeTransaction;

/**
 * Öffnet die Datenbankdatei; `":memory:"` ergibt eine flüchtige Datenbank für Tests. Genau eine
 * Verbindung, deren Zugriffe sich anstellen (`serializedLibsqlClient`) — mehrere Verbindungen auf
 * dieselbe Datei blockieren sich in einem Prozess gegenseitig.
 */
export function connectRuntimeDatabase(databasePath: string): RuntimeDatabase {
  const client = serializedLibsqlClient(createClient({
    url: databasePath === ":memory:" ? "file::memory:" : pathToFileURL(databasePath).href,
    concurrency: 1,
  }));
  return drizzle({client, schema});
}
