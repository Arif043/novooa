import {createRuntimeKeyring, parseRuntimeKeyring} from "./runtime-keyring.js";

export function runtimeKeyringFromSeed(value: string): string {
  const trimmed = value.trim();
  if (trimmed.startsWith("{")) {
    parseRuntimeKeyring(trimmed);
    return value;
  }
  const decoded = Buffer.from(trimmed, "base64");
  if (decoded.length !== 32 || decoded.toString("base64") !== trimmed) {
    throw new Error("Die Setup-Datei muss einen JSON-Schlüsselbund oder einen 32-Byte-Base64-Master-Key enthalten.");
  }
  const keyring = createRuntimeKeyring();
  keyring.keys[keyring.activeKeyId] = trimmed;
  return `${JSON.stringify(keyring)}\n`;
}
