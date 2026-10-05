import {ConnectionAuthError, ConnectionNotFoundError} from "../../domain/entities/connection.js";
import {type ConnectionAuthorizer} from "../../domain/repositories/connection-authorizer.js";
import {OutboundHttpError, type OutboundHttpClient, type OutboundHttpRequest, type OutboundHttpResponse} from "../../domain/repositories/outbound-http-client.js";

export const maximumResponseBytes = 5 * 1024 * 1024;
const maximumRedirects = 5;
const headerNamePattern = /^[A-Za-z0-9!#$%&'*+.^_`|~-]+$/;

/**
 * Sendet Anfragen an externe Systeme, auf Wunsch angemeldet über eine Verbindung.
 *
 * Es gibt bewusst keine Sperre für interne Adressen (siehe docs/features/verbindungen.md). Dafür gilt:
 * Zugangsdaten gehen nur an die Origin der Verbindung — weder eine fremde Adresse im `url`-Feld noch eine
 * Weiterleitung zu einem anderen Host bekommt sie.
 */
export class ConnectionHttpClient implements OutboundHttpClient {
  constructor(private readonly authorizer: ConnectionAuthorizer, private readonly request: typeof fetch = fetch) {}

  async send(request: OutboundHttpRequest): Promise<OutboundHttpResponse> {
    const authorized = request.connectionId === undefined ? undefined : await this.authorizer.authorize(request.teamId, request.connectionId);
    const target = targetUrl(request, authorized?.baseUrl);
    const headers = headersOf(request, authorized?.headers ?? {});
    try {
      return await this.follow(target, request, headers);
    } catch (error) {
      throw translated(error, target, request.timeoutMs);
    }
  }

  private async follow(target: URL, request: OutboundHttpRequest, headers: Record<string, string>): Promise<OutboundHttpResponse> {
    const signal = AbortSignal.timeout(request.timeoutMs);
    let current = target;
    let method = request.method;
    let body = request.body;
    let sent = {...headers};
    for (let redirects = 0; ; redirects++) {
      const response = await this.request(current, {method, headers: sent, body, redirect: "manual", signal});
      const location = response.headers.get("location");
      if (!isRedirect(response.status) || location === null) return resultOf(response);
      const next = new URL(location, current);
      // Eine Weiterleitung zu einem anderen Host wird nicht verfolgt, sondern als Antwort zurückgegeben.
      if (next.origin !== target.origin) return resultOf(response);
      await response.body?.cancel();
      if (redirects >= maximumRedirects) throw new OutboundHttpError("Die Anfrage wurde zu oft weitergeleitet.");
      if (response.status === 303 || ((response.status === 301 || response.status === 302) && method !== "GET")) {
        method = "GET";
        body = undefined;
        sent = Object.fromEntries(Object.entries(sent).filter(([name]) => name !== "content-type"));
      }
      current = next;
    }
  }
}

function targetUrl(request: OutboundHttpRequest, baseUrl: string | undefined): URL {
  const text = request.url.trim();
  let address: string;
  if (/^https?:\/\//i.test(text)) {
    address = text;
  } else if (baseUrl !== undefined) {
    address = baseUrl + (text === "" || text.startsWith("/") || text.startsWith("?") ? text : `/${text}`);
  } else {
    throw new OutboundHttpError("Ohne Verbindung muss die URL mit https:// oder http:// beginnen.");
  }
  let url: URL;
  try {
    url = new URL(address);
  } catch {
    throw new OutboundHttpError("Die URL ist keine gültige Adresse.");
  }
  if (baseUrl !== undefined && url.origin !== new URL(baseUrl).origin) {
    throw new OutboundHttpError("Die URL gehört nicht zur gewählten Verbindung. Gib nur den Pfad an, z. B. /search/order.");
  }
  if (url.username !== "" || url.password !== "") throw new OutboundHttpError("Die URL darf keine Zugangsdaten enthalten.");
  for (const {name, value} of request.query) if (name !== "") url.searchParams.append(name, value);
  return url;
}

function headersOf(request: OutboundHttpRequest, auth: Record<string, string>): Record<string, string> {
  const headers: Record<string, string> = {};
  for (const [name, value] of Object.entries(request.headers)) {
    if (!headerNamePattern.test(name)) throw new OutboundHttpError(`Der Header-Name „${name.slice(0, 40)}“ ist ungültig.`);
    headers[name.toLowerCase()] = value;
  }
  if (request.body !== undefined && headers["content-type"] === undefined) headers["content-type"] = "text/plain; charset=utf-8";
  // Die Anmeldung der Verbindung überschreibt gleichnamige Kopfzeilen des Bausteins.
  return {...headers, ...auth};
}

function isRedirect(status: number): boolean {
  return status === 301 || status === 302 || status === 303 || status === 307 || status === 308;
}

async function resultOf(response: Response): Promise<OutboundHttpResponse> {
  const headers: Record<string, string> = {};
  response.headers.forEach((value, name) => {
    if (name !== "set-cookie") headers[name] = value;
  });
  return {status: response.status, headers, body: await readLimited(response)};
}

async function readLimited(response: Response): Promise<string> {
  const reader = response.body?.getReader();
  if (reader === undefined) return "";
  const chunks: Uint8Array[] = [];
  let size = 0;
  for (;;) {
    const {done, value} = await reader.read();
    if (done) break;
    size += value.length;
    if (size > maximumResponseBytes) {
      await reader.cancel();
      throw new OutboundHttpError(`Die Antwort ist größer als ${maximumResponseBytes / (1024 * 1024)} MB.`);
    }
    chunks.push(value);
  }
  return new TextDecoder().decode(Buffer.concat(chunks));
}

/** Meldungen nennen nur den Host — nie die vollständige Adresse, denn die Query kann Token enthalten. */
function translated(error: unknown, target: URL, timeoutMs: number): Error {
  if (error instanceof OutboundHttpError || error instanceof ConnectionAuthError || error instanceof ConnectionNotFoundError) return error;
  const name = (error as {name?: string} | null)?.name;
  if (name === "TimeoutError" || name === "AbortError") {
    return new OutboundHttpError(`${target.host} hat nicht innerhalb von ${Math.round(timeoutMs / 1000)} Sekunden geantwortet.`);
  }
  const code = ((error as {cause?: {code?: unknown}} | null)?.cause)?.code;
  const reason = typeof code === "string" ? code : "nicht erreichbar";
  return new OutboundHttpError(`Die Anfrage an ${target.host} ist fehlgeschlagen (${reason}).`);
}
