import {getVercelOidcToken} from "@vercel/oidc";
import type {VercelRequest, VercelResponse} from "@vercel/node";
import {forwardedHeaders, isValidSignature, signatureHeader, timestampHeader, upstreamUrlFor} from "../proxy.ts";

/**
 * Reicht lesende Katalog-Abfragen an die skills.sh-API weiter. Aufrufer ist ausschließlich die Firebase-Funktion
 * `localRuntimeSkillsRelay`, die zuvor die Lizenz der Runtime geprüft hat; sie signiert jede Anfrage per HMAC
 * (Zeitstempel, Methode, Pfad+Query). Der Proxy ersetzt die Signatur durch das Vercel-OIDC-Token dieses Projekts
 * (skills.sh erlaubt nur Aufrufe mit einem solchen Token). Status, Rate-Limit-Header (`X-RateLimit-*`,
 * `Retry-After`) und Cache-Control kommen unverändert zurück.
 */
export default async function handler(request: VercelRequest, response: VercelResponse): Promise<void> {
  if (request.method !== "GET") {
    response.status(405).json({error: "method_not_allowed", message: "Nur GET ist erlaubt."});
    return;
  }
  const signed = isValidSignature(
    process.env.SKILLS_PROXY_HMAC_KEY,
    {timestamp: header(request, timestampHeader), signature: header(request, signatureHeader)},
    request.method,
    request.url ?? "",
    Date.now(),
  );
  if (!signed) {
    response.status(401).json({error: "unauthorized", message: "Die Signatur fehlt oder ist ungültig."});
    return;
  }
  const upstream = upstreamUrlFor(request.url ?? "");
  if (upstream === null) {
    response.status(400).json({error: "invalid_path", message: "Dieser Pfad wird nicht weitergegeben."});
    return;
  }
  try {
    const result = await fetch(upstream, {
      headers: {accept: "application/json", authorization: `Bearer ${await getVercelOidcToken()}`},
      signal: AbortSignal.timeout(20_000),
    });
    for (const name of forwardedHeaders) {
      const value = result.headers.get(name);
      if (value !== null) response.setHeader(name, value);
    }
    response.status(result.status).send(Buffer.from(await result.arrayBuffer()));
  } catch {
    response.status(503).json({error: "upstream_unavailable", message: "skills.sh ist nicht erreichbar."});
  }
}

function header(request: VercelRequest, name: string): string | undefined {
  const value = request.headers[name];
  return Array.isArray(value) ? value[0] : value;
}
