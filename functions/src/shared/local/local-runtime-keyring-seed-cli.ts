import {chmod, chown, mkdir, readFile} from "node:fs/promises";
import {dirname} from "node:path";
import {parseRuntimeKeyring} from "../../features/runtime_security/infrastructure/runtime-keyring.js";
import {syncSecretDirectory} from "../../features/runtime_security/infrastructure/durable-secret-file.js";
import {seedRuntimeKeyring} from "../../features/runtime_security/infrastructure/seed-runtime-keyring.js";

void seed().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : "Schlüsselbund konnte nicht eingerichtet werden.");
  process.exitCode = 1;
});

async function seed(): Promise<void> {
  const destination = required("LOCAL_RUNTIME_MASTER_KEY_FILE");
  const directory = dirname(destination);
  await mkdir(directory, {recursive: true, mode: 0o700});
  await seedRuntimeKeyring(required("LOCAL_RUNTIME_MASTER_KEY_SEED_FILE"), destination);
  parseRuntimeKeyring(await readFile(destination, "utf8"));
  await chown(destination, 1000, 1000);
  await chmod(destination, 0o600);
  await chown(directory, 1000, 1000);
  await chmod(directory, 0o700);
  await syncSecretDirectory(directory);
}

function required(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} fehlt.`);
  return value;
}
