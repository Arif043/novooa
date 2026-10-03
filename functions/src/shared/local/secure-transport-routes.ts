import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyInstance} from "fastify";
import {ErrorResponse} from "./local-runtime-http-schemas.js";
import {SecureChannelStore, type SecureChannel} from "./secure-channel-store.js";
import {additionalData, nonceLength, open, seal} from "./secure-transport-crypto.js";

export type SecureTransportOptions = {
  store: SecureChannelStore;
  /** Die Instanz, an die entschlüsselte Anfragen weitergereicht werden (mit allen Hooks und Auth-Prüfungen). */
  target: FastifyInstance;
};

const Handshake = Type.Object({clientPublicKey: Type.String({maxLength: 64}), clientNonce: Type.String({maxLength: 64})});
const HandshakeResponse = Type.Object({
  version: Type.Literal(1), channelId: Type.String(), serverPublicKey: Type.String(), serverNonce: Type.String(),
});
const Exchange = Type.Object({
  channelId: Type.String({maxLength: 64}),
  counter: Type.Integer({minimum: 1}),
  payload: Type.String({maxLength: 3 * 1024 * 1024}),
});
const ExchangeResponse = Type.Object({payload: Type.String()});
const exchangeBodyLimit = 3 * 1024 * 1024;
const allowedMethods = new Set(["GET", "POST", "PUT", "DELETE"]);
const forwardedHeaders = ["accept", "content-type", "authorization"];

type InnerRequest = {method: string; url: string; headers: Record<string, string>; body: string | null};

/**
 * Verschlüsselter Tunnel für die JSON-API. Ein Handshake handelt per X25519 einen
 * Kanal aus; danach verpackt der Client jede Anfrage (Methode, Pfad, `Authorization`,
 * Body) verschlüsselt in `POST /v1/secure/exchange`. Die Runtime entschlüsselt sie,
 * führt sie intern gegen die normalen Routen aus und schickt die Antwort verschlüsselt
 * zurück — die einzelnen Routen wissen davon nichts. Das schützt gegen passives
 * Mitlesen; ein aktiver Man-in-the-Middle beim Handshake ist damit nicht ausgeschlossen.
 */
export const secureTransportRoutes: FastifyPluginAsyncTypebox<SecureTransportOptions> = async (app, {store, target}) => {
  app.post("/v1/secure/handshake", {
    schema: {body: Handshake, response: {200: HandshakeResponse, 400: ErrorResponse}},
  }, async (request, reply) => {
    const clientPublicKey = Buffer.from(request.body.clientPublicKey, "base64");
    const clientNonce = Buffer.from(request.body.clientNonce, "base64");
    if (clientPublicKey.length !== 32 || clientNonce.length !== nonceLength) {
      return reply.code(400).send({error: "Ungültiger Schlüsselaustausch.", code: "secure_invalid"});
    }
    const result = store.open(clientPublicKey, clientNonce);
    return {
      version: 1 as const, channelId: result.channelId,
      serverPublicKey: result.serverPublicKey.toString("base64"), serverNonce: result.serverNonce.toString("base64"),
    };
  });

  app.post("/v1/secure/exchange", {
    bodyLimit: exchangeBodyLimit,
    schema: {body: Exchange, response: {200: ExchangeResponse, 400: ErrorResponse, 404: ErrorResponse, 409: ErrorResponse}},
  }, async (request, reply) => {
    const {channelId, counter, payload} = request.body;
    const channel = store.find(channelId);
    if (channel === undefined) return reply.code(404).send(failure("Der verschlüsselte Kanal ist unbekannt oder abgelaufen.", "secure_channel_unknown"));
    const inner = openRequest(channel, counter, payload);
    if (inner === null) return reply.code(400).send(failure("Die verschlüsselte Anfrage ist ungültig.", "secure_invalid"));
    // Erst nach erfolgreicher Entschlüsselung verbrauchen — und ohne await dazwischen, damit eine parallele Wiederholung scheitert.
    if (!channel.acceptCounter(counter)) return reply.code(409).send(failure("Die Anfrage wurde bereits verarbeitet.", "secure_replay"));
    if (!isForwardable(inner)) return reply.code(400).send(failure("Dieser Endpunkt ist nicht über den Tunnel erreichbar.", "secure_forbidden"));
    return {payload: await sealedResponse(channel, counter, await dispatch(target, inner))};
  });
};

function failure(error: string, code: string) {
  return {error, code} as never;
}

function openRequest(channel: SecureChannel, counter: number, payload: string): InnerRequest | null {
  try {
    const plain = open(channel.keys.clientToServer, payload, additionalData(channel.id, "req", counter));
    return innerRequestFrom(JSON.parse(plain.toString("utf8")));
  } catch {
    return null;
  }
}

function innerRequestFrom(value: unknown): InnerRequest | null {
  if (typeof value !== "object" || value === null) return null;
  const input = value as Record<string, unknown>;
  const headers = input.headers;
  if (typeof input.method !== "string" || typeof input.url !== "string") return null;
  if (typeof headers !== "object" || headers === null) return null;
  if (input.body !== null && typeof input.body !== "string") return null;
  return {method: input.method.toUpperCase(), url: input.url, headers: headers as Record<string, string>, body: input.body};
}

function isForwardable(inner: InnerRequest): boolean {
  if (!allowedMethods.has(inner.method)) return false;
  if (!inner.url.startsWith("/v1/") || inner.url.startsWith("/v1/secure")) return false;
  return !inner.url.includes("..") && !inner.url.includes("\\");
}

async function dispatch(target: FastifyInstance, inner: InnerRequest) {
  const headers: Record<string, string> = {};
  for (const name of forwardedHeaders) {
    const value = inner.headers[name];
    if (typeof value === "string") headers[name] = value;
  }
  const response = await target.inject({
    method: inner.method as "GET" | "POST" | "PUT" | "DELETE", url: inner.url, headers,
    ...(inner.body === null ? {} : {payload: inner.body}),
  });
  const contentType = String(response.headers["content-type"] ?? "");
  const isJson = contentType.startsWith("application/json") || response.body.length === 0;
  return isJson
    ? {status: response.statusCode, contentType, body: response.body}
    : {status: 415, contentType: "application/json", body: JSON.stringify({error: "Die Antwort ist nicht als JSON verfügbar."})};
}

async function sealedResponse(channel: SecureChannel, counter: number, response: object): Promise<string> {
  return seal(channel.keys.serverToClient, Buffer.from(JSON.stringify(response), "utf8"), additionalData(channel.id, "res", counter));
}

