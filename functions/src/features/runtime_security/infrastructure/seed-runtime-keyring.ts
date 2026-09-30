import {randomUUID} from "node:crypto";
import {link, readFile, rm} from "node:fs/promises";
import {dirname} from "node:path";
import {parseRuntimeKeyring} from "./runtime-keyring.js";
import {syncSecretDirectory, writeDurableSecretFile} from "./durable-secret-file.js";
import {runtimeKeyringFromSeed} from "./runtime-keyring-from-seed.js";

export async function seedRuntimeKeyring(source: string, destination: string): Promise<void> {
  if (await keyringExists(destination)) return;
  const value = runtimeKeyringFromSeed(await readFile(source, "utf8"));
  const temporary = `${destination}.${randomUUID()}.seed`;
  try {
    await writeDurableSecretFile(temporary, value);
    await publishSeed(temporary, destination);
    await syncSecretDirectory(dirname(destination));
  } finally {
    await rm(temporary, {force: true});
  }
}

async function keyringExists(destination: string): Promise<boolean> {
  try {
    parseRuntimeKeyring(await readFile(destination, "utf8"));
    return true;
  } catch (error) {
    if (isCode(error, "ENOENT")) return false;
    throw error;
  }
}

async function publishSeed(temporary: string, destination: string): Promise<void> {
  try {
    await link(temporary, destination);
  } catch (error) {
    if (!isCode(error, "EEXIST")) throw error;
  }
}

function isCode(error: unknown, code: string): boolean {
  return error instanceof Error && "code" in error && error.code === code;
}
