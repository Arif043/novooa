/** Das Ereignis, das ein empfangener Webhook in den Lauf der Aufgabe trägt (`input.event`). */
export type WebhookEvent = {
  type: "webhookReceived";
  method: string;
  query: Record<string, string>;
  headers: Record<string, string>;
  /** JSON und Formulare als Objekt, alles andere als Text. */
  body: unknown;
  receivedAt: string;
};

export type WebhookRequest = {
  triggerId: string;
  token: string;
  method: string;
  query: Record<string, string>;
  headers: Record<string, string>;
  rawBody: Buffer;
};

/** Diese Kopfzeilen tragen Zugangsdaten und gehören weder in den Lauf noch ins Aktivitätslog. */
const sensitiveHeaders: ReadonlySet<string> = new Set(["authorization", "proxy-authorization", "cookie", "set-cookie"]);

export function webhookEventFrom(request: WebhookRequest, signatureHeader: string | undefined, now: Date): WebhookEvent {
  return {
    type: "webhookReceived",
    method: request.method,
    query: request.query,
    headers: publicHeaders(request.headers, signatureHeader),
    body: bodyFrom(request.headers["content-type"] ?? "", request.rawBody),
    receivedAt: now.toISOString(),
  };
}

export function webhookContextText(event: WebhookEvent, byteLength: number): string {
  const type = event.headers["content-type"];
  return ["Webhook empfangen", `Methode: ${event.method}`, ...(type === undefined ? [] : [`Inhalt: ${type}`]), `Größe: ${byteLength} Byte`].join("\n");
}

function publicHeaders(headers: Record<string, string>, signatureHeader: string | undefined): Record<string, string> {
  return Object.fromEntries(Object.entries(headers).filter(([name]) => !sensitiveHeaders.has(name) && name !== signatureHeader));
}

function bodyFrom(contentType: string, raw: Buffer): unknown {
  const text = raw.toString("utf8");
  const type = contentType.split(";")[0]?.trim().toLowerCase() ?? "";
  if (type === "application/json" || type.endsWith("+json")) {
    try {
      return JSON.parse(text) as unknown;
    } catch {
      return text;
    }
  }
  if (type === "application/x-www-form-urlencoded") return Object.fromEntries(new URLSearchParams(text));
  return text;
}
