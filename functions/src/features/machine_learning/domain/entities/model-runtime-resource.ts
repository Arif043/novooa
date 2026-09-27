export type ModelRuntimeResource = {
  readonly name: string;
  readonly contentType: string;
  readonly sha256: string;
  readonly bytes: Uint8Array;
};

export function validateModelRuntimeResources(
  resources: readonly ModelRuntimeResource[],
): void {
  const names = new Set<string>();
  for (const resource of resources) validateResource(resource, names);
}

function validateResource(resource: ModelRuntimeResource, names: Set<string>): void {
  required(resource.name, "Der Name einer Modellressource fehlt.");
  required(resource.contentType, "Der Content-Type einer Modellressource fehlt.");
  if (resource.bytes.byteLength === 0) throw new Error("Eine Modellressource darf nicht leer sein.");
  if (!/^[a-f0-9]{64}$/i.test(resource.sha256)) {
    throw new Error("Die SHA-256-Prüfsumme einer Modellressource ist ungültig.");
  }
  if (names.has(resource.name)) throw new Error("Die Namen der Modellressourcen müssen eindeutig sein.");
  names.add(resource.name);
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
