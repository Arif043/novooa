import {access} from "node:fs/promises";
import {join, resolve} from "node:path";
import {connectRuntimeDatabase} from "../../db/database.js";
import {RotateRuntimeMasterKey} from "../../features/runtime_security/domain/usecases/rotate-runtime-master-key.js";
import {FileRuntimeKeyRepository} from "../../features/runtime_security/infrastructure/file-runtime-key-repository.js";
import {LocalRuntimeSecretRotationStore} from "../../features/runtime_security/infrastructure/local-runtime-secret-rotation-store.js";
import {acquireLocalRuntimeProcessLock} from "./local-runtime-process-lock.js";

void rotate().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : "Master-Key-Rotation fehlgeschlagen.");
  process.exitCode = 1;
});

async function rotate(): Promise<void> {
  const args = process.argv.slice(2);
  const runtimeRoot = argument(args, "--runtime-root", "LOCAL_RUNTIME_ROOT");
  const secretFile = argument(args, "--secret-file", "LOCAL_RUNTIME_MASTER_KEY_FILE");
  const databasePath = join(runtimeRoot, "novooa.sqlite");
  await access(databasePath);
  const release = await acquireLocalRuntimeProcessLock(runtimeRoot);
  try {
    await rotateDatabase(databasePath, runtimeRoot, secretFile, args.includes("--retire-old-keys"));
  } finally {
    await release();
  }
}

async function rotateDatabase(path: string, root: string, secretFile: string, retire: boolean): Promise<void> {
  const database = connectRuntimeDatabase(path);
  try {
    const workflow = new RotateRuntimeMasterKey(
      new FileRuntimeKeyRepository(secretFile), new LocalRuntimeSecretRotationStore(database, root),
    );
    const count = await workflow.execute(retire);
    console.info(`Master-Key-Rotation abgeschlossen. ${count} Datenschlüssel umgeschlüsselt.`);
    console.info(retire ? "Alte Master-Keys entfernt." : "Alte Master-Keys für Backups beibehalten.");
  } finally {
    database.$client.close();
  }
}

function argument(args: string[], flag: string, environment: string): string {
  const index = args.indexOf(flag);
  const value = index < 0 ? process.env[environment] : args[index + 1];
  if (!value || value.startsWith("--")) throw new Error(`${flag} <pfad> oder ${environment} fehlt.`);
  return resolve(value);
}
