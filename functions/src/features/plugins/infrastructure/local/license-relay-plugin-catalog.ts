import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {PluginCatalogError, type PluginCatalogEntry} from "../../domain/entities/plugin-catalog.js";
import {type PluginCatalog} from "../../domain/repositories/plugin-catalog.js";

const requestTimeoutMilliseconds = 60_000;

/** Katalog über das Relay in Firebase (`localRuntimePluginsRelay`); die Runtime weist sich mit ihrer Lizenz aus. */
export class LicenseRelayPluginCatalog implements PluginCatalog {
  constructor(
    private readonly relayUrl: string,
    private readonly license: () => SignedRuntimeLicense | null,
    private readonly request: typeof fetch = fetch,
  ) {
    if (new URL(relayUrl).protocol !== "https:") throw new Error("Das Plugin-Relay muss HTTPS verwenden.");
  }

  async list(): Promise<PluginCatalogEntry[]> {
    const response = await this.send({action: "list"});
    return ((await response.json()) as {items: PluginCatalogEntry[]}).items;
  }

  async download(id: string, version?: string): Promise<Uint8Array> {
    const response = await this.send({action: "download", id, ...(version === undefined ? {} : {version})});
    return new Uint8Array(await response.arrayBuffer());
  }

  private async send(body: Record<string, unknown>): Promise<Response> {
    const license = this.license();
    if (license === null) throw new PluginCatalogError("Für den Plugin-Katalog ist eine aktive Lizenz nötig. Aktiviere die Runtime zuerst.", "unauthorized");
    let response: Response;
    try {
      response = await this.request(this.relayUrl, {
        method: "POST",
        headers: {"content-type": "application/json"},
        body: JSON.stringify({license, ...body}),
        signal: AbortSignal.timeout(requestTimeoutMilliseconds),
      });
    } catch {
      throw new PluginCatalogError("Der Plugin-Katalog ist nicht erreichbar.", "unavailable");
    }
    if (response.ok) return response;
    const message = ((await response.json().catch(() => ({}))) as {message?: string}).message;
    if (response.status === 401) throw new PluginCatalogError(message ?? "Die Lizenz wurde abgelehnt.", "unauthorized");
    if (response.status === 429) throw new PluginCatalogError(message ?? "Zu viele Anfragen. Bitte später erneut versuchen.", "rate_limited");
    if (response.status === 404) throw new PluginCatalogError(message ?? "Nicht im Katalog gefunden.", "not_found");
    if (response.status === 400) throw new PluginCatalogError(message ?? "Ungültige Anfrage.", "invalid");
    throw new PluginCatalogError("Der Plugin-Katalog ist nicht erreichbar.", "unavailable");
  }
}
