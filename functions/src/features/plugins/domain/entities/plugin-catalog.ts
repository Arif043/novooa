export type PluginCatalogEntry = {
  id: string;
  name: string;
  description: string;
  /** Aktuelle veröffentlichte Version. */
  version: string;
  sizeBytes: number;
};

export type PluginCatalogErrorKind = "unauthorized" | "rate_limited" | "not_found" | "unavailable" | "invalid";

export class PluginCatalogError extends Error {
  constructor(message: string, readonly kind: PluginCatalogErrorKind) {
    super(message);
    this.name = "PluginCatalogError";
  }
}

const identifier = /^[a-z][a-z0-9-]{1,39}$/;
const version = /^\d+\.\d+\.\d+$/;

/** Prüft eine Download-Anfrage, bevor sie einen Storage-Pfad bildet. */
export function pluginDownloadRequestFrom(id: unknown, requestedVersion: unknown): {id: string; version?: string} {
  if (typeof id !== "string" || !identifier.test(id)) throw new PluginCatalogError("Die Plugin-ID ist ungültig.", "invalid");
  if (requestedVersion === undefined) return {id};
  if (typeof requestedVersion !== "string" || !version.test(requestedVersion)) throw new PluginCatalogError("Die Version ist ungültig.", "invalid");
  return {id, version: requestedVersion};
}
