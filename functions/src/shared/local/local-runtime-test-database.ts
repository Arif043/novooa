import {resolve} from "node:path";
import {type RuntimeDatabase} from "../../db/database.js";
import {CurrentRuntimeFieldCipher} from "../../features/runtime_security/infrastructure/current-runtime-field-cipher.js";
import {createRuntimeKeyring} from "../../features/runtime_security/infrastructure/runtime-keyring.js";
import {openLocalRuntimeDatabase} from "./local-runtime-database.js";
import {ensureLocalRuntimeWorkspace, type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";

/** Nur Tests: Arbeitsbereich mit Team `team-1`, dessen Profil `owner-1` gehört. */
export const testRuntimeWorkspace: LocalRuntimeWorkspace = {teamId: "team-1", teamName: "Test", userId: "owner-1"};

/** Nur Tests: Feldverschlüsselung mit einem frischen Schlüsselbund. */
export function testRuntimeFieldCipher(): CurrentRuntimeFieldCipher {
  return new CurrentRuntimeFieldCipher(JSON.stringify(createRuntimeKeyring()));
}

/** Nur Tests: frische, migrierte In-Memory-Datenbank mit eingerichtetem Arbeitsbereich (wie nach der Lizenzaktivierung). */
export async function withRuntimeTestDatabase(operation: (database: RuntimeDatabase) => Promise<void>): Promise<void> {
  const database = await openLocalRuntimeDatabase({databasePath: ":memory:", migrationsDirectory: resolve(__dirname, "../../../drizzle")});
  try {
    await ensureLocalRuntimeWorkspace(database, testRuntimeWorkspace);
    await operation(database);
  } finally {
    database.$client.close();
  }
}
