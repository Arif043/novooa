import {randomBytes} from "node:crypto";
import {chmod, mkdir, open, readFile} from "node:fs/promises";
import {dirname} from "node:path";
import {CredentialCipher} from "../../features/communication/infrastructure/security/credential-cipher.js";

const masterKeyBytes = 32;

export async function prepareLocalRuntimeMasterKey(filePath: string): Promise<boolean> {
  await mkdir(dirname(filePath), {recursive: true, mode: 0o700});
  try {
    const file = await open(filePath, "wx", 0o600);
    try {
      await file.writeFile(`${randomBytes(masterKeyBytes).toString("base64")}\n`, "utf8");
    } finally {
      await file.close();
    }
    return true;
  } catch (error) {
    if (isExistingFile(error)) {
      await chmod(filePath, 0o600);
      return false;
    }
    throw error;
  }
}

export async function localRuntimeMasterKeyFrom(filePath: string): Promise<string> {
  const key = (await readFile(filePath, "utf8")).trim();
  new CredentialCipher(key, "LOCAL_RUNTIME_MASTER_KEY");
  return key;
}

function isExistingFile(error: unknown): error is NodeJS.ErrnoException {
  return typeof error === "object" && error !== null && (error as NodeJS.ErrnoException).code === "EEXIST";
}
