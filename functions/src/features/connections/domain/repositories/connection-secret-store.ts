import {type RuntimeExecutor} from "../../../../db/database.js";

/** Verschlüsselter Speicher für Geheimnisse; derselbe Speicher wie bei den Sprachmodellen (siehe docs/notes/verbindung.md). */
export interface ConnectionSecretStore {
  read(secretRef: string): Promise<string | null>;
  write(secretRef: string, value: string): Promise<void>;
  delete(secretRef: string): Promise<void>;
  withDatabase(database: RuntimeExecutor): Omit<ConnectionSecretStore, "withDatabase">;
}
