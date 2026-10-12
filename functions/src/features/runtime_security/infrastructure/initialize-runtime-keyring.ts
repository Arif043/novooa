import {randomUUID} from "node:crypto";
import {link, readFile, rm} from "node:fs/promises";
import {dirname} from "node:path";
import {createRuntimeKeyring, parseRuntimeKeyring} from "./runtime-keyring.js";
import {syncSecretDirectory, writeDurableSecretFile} from "./durable-secret-file.js";

/**
 * Legt beim ersten Start einen zufälligen Schlüsselbund an; ein vorhandener bleibt unberührt, denn ab dann
 * rotiert ihn die Runtime selbst. Veröffentlicht wird per Hardlink, damit gleichzeitige Starts nie eine
 * halb geschriebene Datei sehen und genau ein Schlüsselbund gewinnt.
 * @return `true`, wenn ein neuer Schlüsselbund entstanden ist.
 */
export async function initializeRuntimeKeyring(destination: string): Promise<boolean> {
  if (await keyringExists(destination)) return false;
  const temporary = `${destination}.${randomUUID()}.init`;
  try {
    await writeDurableSecretFile(temporary, `${JSON.stringify(createRuntimeKeyring())}\n`);
    const created = await publish(temporary, destination);
    await syncSecretDirectory(dirname(destination));
    return created;
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

async function publish(temporary: string, destination: string): Promise<boolean> {
  try {
    await link(temporary, destination);
    return true;
  } catch (error) {
    if (!isCode(error, "EEXIST")) throw error;
    return false;
  }
}

function isCode(error: unknown, code: string): boolean {
  return error instanceof Error && "code" in error && error.code === code;
}
