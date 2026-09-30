import {chmod, mkdir, open, readFile} from "node:fs/promises";
import {dirname} from "node:path";
import {createRuntimeKeyring, parseRuntimeKeyring} from "../../features/runtime_security/infrastructure/runtime-keyring.js";
import {syncSecretDirectory} from "../../features/runtime_security/infrastructure/durable-secret-file.js";

export async function prepareLocalRuntimeMasterKey(filePath: string): Promise<boolean> {
  await mkdir(dirname(filePath), {recursive: true, mode: 0o700});
  try {
    await createMasterKeyFile(filePath);
    return true;
  } catch (error) {
    if (isExistingFile(error)) {
      await chmod(filePath, 0o600);
      return false;
    }
    throw error;
  }
}

async function createMasterKeyFile(filePath: string): Promise<void> {
  const file = await open(filePath, "wx", 0o600);
  try {
    await file.writeFile(`${JSON.stringify(createRuntimeKeyring())}\n`, "utf8");
    await file.sync();
  } finally {
    await file.close();
  }
  await syncSecretDirectory(dirname(filePath));
}

export async function localRuntimeMasterKeyFrom(filePath: string): Promise<string> {
  const key = (await readFile(filePath, "utf8")).trim();
  parseRuntimeKeyring(key);
  return key;
}

function isExistingFile(error: unknown): error is NodeJS.ErrnoException {
  return typeof error === "object" && error !== null && (error as NodeJS.ErrnoException).code === "EEXIST";
}
