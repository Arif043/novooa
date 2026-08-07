import {type MailProviderToken} from "../../domain/repositories/mail-provider.js";
import {tokenFrom} from "./microsoft-graph-mappers.js";

export async function tokenFromForm(
  parameters: URLSearchParams,
): Promise<MailProviderToken> {
  const response = await fetch("https://login.microsoftonline.com/common/oauth2/v2.0/token", {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: parameters,
  });
  const data = await response.json() as Record<string, unknown>;
  if (!response.ok) throw new Error(`Microsoft token request failed: ${errorFrom(data)}.`);
  return tokenFrom(data);
}

export async function graphJson(
  path: string,
  accessToken: string,
  body?: Record<string, unknown>,
  headers?: Record<string, string>,
  method?: "POST" | "PATCH",
): Promise<Record<string, unknown>> {
  const response = await graphRequest(path, accessToken, body, headers, method);
  return response.json() as Promise<Record<string, unknown>>;
}

export async function graphRequest(
  path: string,
  accessToken: string,
  body?: Record<string, unknown>,
  headers?: Record<string, string>,
  method?: "POST" | "PATCH",
): Promise<Response> {
  const response = await fetch(`https://graph.microsoft.com${path}`, {
    method: method ?? (body ? "POST" : "GET"),
    headers: requestHeaders(accessToken, body, headers),
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!response.ok) throw new Error(`Microsoft Graph request failed: ${await errorText(response)}.`);
  return response;
}

function requestHeaders(
  accessToken: string,
  body: Record<string, unknown> | undefined,
  headers: Record<string, string> | undefined,
): Record<string, string> {
  return {
    Authorization: `Bearer ${accessToken}`,
    ...headers,
    ...(body ? {"Content-Type": "application/json"} : {}),
  };
}

async function errorText(response: Response): Promise<string> {
  const value = await response.json().catch(() => ({})) as Record<string, unknown>;
  return errorFrom(value);
}

function errorFrom(value: Record<string, unknown>): string {
  return isRecord(value.error) ? stringFrom(value.error.message) || "unknown error" : "unknown error";
}

function stringFrom(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
