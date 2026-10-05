import {type OutboundHttpClient} from "../../../connections/domain/repositories/outbound-http-client.js";
import {ShopwareError, shopwareFailureMessage} from "../domain/shopware-error.js";

type Method = "GET" | "POST" | "PATCH" | "DELETE";
export type ShopwareRecord = Record<string, unknown>;
export type ShopwareSearchResult = {data: ShopwareRecord[]; total: number};

/** Shopware erlaubt höchstens 500 Datensätze je Seite. */
export const maximumPageSize = 500;
const entityNamePattern = /^[a-z][a-z0-9_]{0,99}$/;

/**
 * Dünner Zugang zur Admin-API von Shopware 6 über eine gespeicherte Verbindung. Anmeldung (OAuth, Token-Cache) und
 * Schutz der Zugangsdaten übernimmt der `OutboundHttpClient`; hier stehen nur Form und Fehler der Shopware-API.
 */
export class ShopwareClient {
  constructor(
    private readonly http: OutboundHttpClient,
    private readonly teamId: string,
    private readonly connectionId: string,
    private readonly timeoutMs = 30_000,
  ) {}

  /** Wirft `ShopwareError` bei Fehlerstatus; Netzwerk- und Anmeldefehler des `OutboundHttpClient` bleiben, wie sie sind. */
  async request(method: Method, path: string, body?: unknown): Promise<{status: number; data: unknown}> {
    if (!path.startsWith("/api/")) throw new ShopwareError("Interner Fehler: Der Pfad muss mit /api/ beginnen.");
    const response = await this.http.send({
      teamId: this.teamId,
      connectionId: this.connectionId,
      method,
      url: path,
      query: [],
      headers: {accept: "application/json", ...(body === undefined ? {} : {"content-type": "application/json"})},
      ...(body === undefined ? {} : {body: JSON.stringify(body)}),
      timeoutMs: this.timeoutMs,
    });
    if (response.status < 200 || response.status >= 300) {
      throw new ShopwareError(shopwareFailureMessage(response.status, response.body), response.status);
    }
    return {status: response.status, data: parsed(response.body)};
  }

  /** Eine Seite einer Suche (`POST /api/search/<entity>`) samt Gesamtzahl. */
  async search(entity: string, criteria: ShopwareRecord): Promise<ShopwareSearchResult> {
    if (!entityNamePattern.test(entity)) throw new ShopwareError("Der Name der Entität ist ungültig.");
    const {data} = await this.request("POST", `/api/search/${entity}`, {"total-count-mode": 1, ...criteria});
    const result = (typeof data === "object" && data !== null ? data : {}) as {data?: unknown; total?: unknown};
    const records = Array.isArray(result.data) ? result.data.filter(isRecord) : [];
    return {data: records, total: typeof result.total === "number" ? result.total : records.length};
  }

  /**
   * Sammelt bis zu `limit` Datensätze über mehrere Seiten; `total` ist die Gesamtzahl in Shopware. Die Seitengröße bleibt
   * über alle Seiten gleich, sonst verschöbe sich der Versatz zwischen den Seiten.
   */
  async searchAll(entity: string, criteria: ShopwareRecord, limit: number): Promise<ShopwareSearchResult> {
    const wanted = Math.max(1, Math.floor(limit));
    const pageSize = Math.min(wanted, maximumPageSize);
    const collected: ShopwareRecord[] = [];
    let total = 0;
    for (let page = 1; collected.length < wanted; page += 1) {
      const result = await this.search(entity, {...criteria, limit: pageSize, page});
      total = result.total;
      collected.push(...result.data);
      if (result.data.length < pageSize || collected.length >= total) break;
    }
    return {data: collected.slice(0, wanted), total};
  }

  async version(): Promise<string> {
    const {data} = await this.request("GET", "/api/_info/version");
    const version = typeof data === "object" && data !== null ? (data as {version?: unknown}).version : undefined;
    return typeof version === "string" ? version : "unbekannt";
  }
}

function parsed(body: string): unknown {
  if (body.trim() === "") return null;
  try {
    return JSON.parse(body) as unknown;
  } catch {
    return body;
  }
}

function isRecord(value: unknown): value is ShopwareRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
