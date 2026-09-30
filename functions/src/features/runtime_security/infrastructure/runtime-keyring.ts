import {randomBytes, randomUUID} from "node:crypto";

export type RuntimeKeyring = {
  version: 1;
  activeKeyId: string;
  keys: Record<string, string>;
  rotationPending: boolean;
  lastRotatedAt?: string;
};

export function createRuntimeKeyring(): RuntimeKeyring {
  const activeKeyId = randomUUID();
  return {
    version: 1, activeKeyId, rotationPending: false, lastRotatedAt: new Date().toISOString(),
    keys: {[activeKeyId]: randomBytes(32).toString("base64")},
  };
}

export function parseRuntimeKeyring(value: string): RuntimeKeyring {
  const parsed: unknown = keyringJson(value);
  if (!isRecord(parsed) || parsed.version !== 1 || typeof parsed.activeKeyId !== "string" ||
      typeof parsed.rotationPending !== "boolean" || !isRecord(parsed.keys)) {
    throw new Error("Ungültiger Runtime-Schlüsselbund. Bitte die Runtime neu einrichten.");
  }
  const keys = Object.fromEntries(Object.entries(parsed.keys).map(validateKey));
  if (!Object.prototype.hasOwnProperty.call(keys, parsed.activeKeyId)) throw new Error("Aktiver Master-Key fehlt.");
  const lastRotatedAt = rotationTime(parsed.lastRotatedAt);
  return {version: 1, activeKeyId: parsed.activeKeyId, rotationPending: parsed.rotationPending, keys, lastRotatedAt};
}

function keyringJson(value: string): unknown {
  try {
    return JSON.parse(value);
  } catch {
    throw new Error("Ungültiger Runtime-Schlüsselbund. Erwartet wird ein JSON-Schlüsselbund.");
  }
}

function rotationTime(value: unknown): string | undefined {
  if (value === undefined) return undefined;
  if (typeof value !== "string" || !Number.isFinite(new Date(value).getTime())) {
    throw new Error("Ungültiger Rotationszeitpunkt im Schlüsselbund.");
  }
  return value;
}

function validateKey([id, value]: [string, unknown]): [string, string] {
  if (!/^[a-zA-Z0-9-]{1,100}$/.test(id) || typeof value !== "string" ||
      Buffer.from(value, "base64").length !== 32 ||
      Buffer.from(value, "base64").toString("base64") !== value) {
    throw new Error("Ungültiger Runtime-Master-Key.");
  }
  return [id, value];
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
