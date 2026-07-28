import type {Request} from "firebase-functions/v2/https";

export function formFieldsFromRequest(
  request: Request,
): Record<string, string> {
  const body = request.body as unknown;
  if (typeof body === "string") return fieldsFromSearchParams(body);
  if (Buffer.isBuffer(body)) return fieldsFromSearchParams(body.toString());
  if (isRecord(body)) return stringFieldsFrom(body);
  return {};
}

export function teamIdFromRequest(request: Request): string {
  return queryValue(request.query.teamId, "teamId");
}

export function channelIdFromRequest(request: Request): string {
  return queryValue(request.query.channelId, "channelId");
}

export function publicRequestUrl(request: Request): string {
  const override = process.env.TWILIO_WEBHOOK_PUBLIC_URL?.trim();
  if (override) return override;
  const protocol = request.get("x-forwarded-proto") ?? request.protocol;
  const host = request.get("x-forwarded-host") ?? request.get("host") ?? "";
  return `${protocol}://${host}${request.originalUrl}`;
}

function fieldsFromSearchParams(input: string): Record<string, string> {
  const fields: Record<string, string> = {};
  new URLSearchParams(input).forEach((value, key) => {
    fields[key] = value;
  });
  return fields;
}

function stringFieldsFrom(input: Record<string, unknown>): Record<string, string> {
  const fields: Record<string, string> = {};
  for (const [key, value] of Object.entries(input)) {
    fields[key] = Array.isArray(value) ? String(value[0] ?? "") : String(value);
  }
  return fields;
}

function queryValue(value: unknown, name: string): string {
  const normalized = optionalQueryValue(value);
  if (normalized) return normalized;
  throw new Error(`${name} query parameter is required.`);
}

function optionalQueryValue(value: unknown): string | undefined {
  const normalized = Array.isArray(value) ? value[0] : value;
  if (typeof normalized === "string" && normalized.trim().length > 0) {
    return normalized.trim();
  }
  return undefined;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
