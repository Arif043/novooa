import assert from "node:assert/strict";
import {createPrivateKey, type KeyObject} from "node:crypto";
import test from "node:test";
import Fastify, {type FastifyInstance} from "fastify";
import {SecureChannelStore} from "./secure-channel-store.js";
import {secureTransportRoutes} from "./secure-transport-routes.js";
import {
  additionalData,
  deriveSessionKeys,
  generateEphemeralKeyPair,
  open,
  seal,
  type SessionKeys,
} from "./secure-transport-crypto.js";

// Gemeinsamer Testvektor mit dem Dart-Client (test/core/network/secure_transport_test.dart).
const vector = {
  clientPrivate: Buffer.from(Array.from({length: 32}, (_, index) => 1 + index)),
  serverPrivate: Buffer.from(Array.from({length: 32}, (_, index) => 101 + index)),
  clientPublic: "07a37cbc142093c8b755dc1b10e86cb426374ad16aa853ed0bdfc0b2b86d1c7c",
  serverPublic: "5714769d116bf76436ae74bc793d2c30ad1903c59ac5273805c7e2698b410c36",
  clientNonce: Buffer.alloc(16, 0xa1),
  serverNonce: Buffer.alloc(16, 0xb2),
  clientToServer: "ff99147472428379a96929b575f57564a97ea7ec35d90c77f9ce3e75344d31fc",
  serverToClient: "a30822dc5589eb6d32b19427609f0408d25b0e735e8aa9e53a6224b7433a1840",
};

function privateKeyFrom(raw: Buffer): KeyObject {
  return createPrivateKey({
    key: Buffer.concat([Buffer.from("302e020100300506032b656e04220420", "hex"), raw]),
    format: "der", type: "pkcs8",
  });
}

test("beide Seiten leiten aus dem Testvektor dieselben Schlüssel ab", () => {
  const fromClient = deriveSessionKeys(
    privateKeyFrom(vector.clientPrivate), Buffer.from(vector.serverPublic, "hex"), vector.clientNonce, vector.serverNonce,
  );
  const fromServer = deriveSessionKeys(
    privateKeyFrom(vector.serverPrivate), Buffer.from(vector.clientPublic, "hex"), vector.clientNonce, vector.serverNonce,
  );

  assert.equal(fromClient.clientToServer.toString("hex"), vector.clientToServer);
  assert.equal(fromClient.serverToClient.toString("hex"), vector.serverToClient);
  assert.deepEqual(fromServer, fromClient);
});

test("öffnet einen vom Dart-Client erzeugten Umschlag", () => {
  const key = Buffer.from(Array.from({length: 32}, (_, index) => index));
  const envelope = "dMJeDQhpHUXypZQDLrInmwk9OZQp3HeQOOvGbfqY/dcmeVM/j3aQFURdhIqf";

  const plain = open(key, envelope, additionalData("abc", "res", 9));

  assert.equal(plain.toString("utf8"), '{"von":"Dart ü"}');
});

test("Verschlüsseln und Entschlüsseln ergeben den Klartext zurück", () => {
  const key = Buffer.alloc(32, 7);
  const aad = additionalData("kanal", "req", 1);
  const envelope = seal(key, Buffer.from("geheim"), aad);

  assert.equal(open(key, envelope, aad).toString(), "geheim");
  assert.notEqual(seal(key, Buffer.from("geheim"), aad), envelope, "jede Nachricht hat einen eigenen IV");
});

test("veränderte Daten, falscher Schlüssel oder falsche Zusatzdaten werden abgelehnt", () => {
  const key = Buffer.alloc(32, 7);
  const aad = additionalData("kanal", "req", 1);
  const raw = Buffer.from(seal(key, Buffer.from("geheim"), aad), "base64");
  raw[14] ^= 1;

  assert.throws(() => open(key, raw.toString("base64"), aad));
  assert.throws(() => open(Buffer.alloc(32, 8), seal(key, Buffer.from("x"), aad), aad));
  assert.throws(() => open(key, seal(key, Buffer.from("x"), aad), additionalData("kanal", "req", 2)));
  assert.throws(() => open(key, seal(key, Buffer.from("x"), aad), additionalData("kanal", "res", 1)));
  assert.throws(() => open(key, "AAAA", aad), "zu kurzer Umschlag");
});

type TestClient = {
  channelId: string;
  keys: SessionKeys;
  exchange(counter: number, request: object): Promise<{statusCode: number; body: Record<string, unknown>}>;
  sealedFor(counter: number, request: object): string;
  decode(counter: number, payload: string): {status: number; contentType: string; body: string};
};

async function server(store = new SecureChannelStore()) {
  const app = Fastify();
  app.register(secureTransportRoutes, {store, target: app});
  app.get("/v1/echo", async (request) => ({authorization: request.headers.authorization ?? null, query: request.query}));
  app.post("/v1/items", async (request, reply) => reply.code(201).send({received: request.body}));
  app.get("/v1/binary", async (_request, reply) => reply.type("application/zip").send(Buffer.from("zip")));
  app.get("/healthz", async () => ({status: "ok"}));
  await app.ready();
  return {app, store};
}

async function connect(app: FastifyInstance): Promise<TestClient> {
  const pair = generateEphemeralKeyPair();
  const clientNonce = Buffer.alloc(16, 5);
  const response = await app.inject({
    method: "POST", url: "/v1/secure/handshake",
    payload: {clientPublicKey: pair.publicKey.toString("base64"), clientNonce: clientNonce.toString("base64")},
  });
  const handshake = response.json() as {channelId: string; serverPublicKey: string; serverNonce: string};
  const keys = deriveSessionKeys(
    pair.privateKey, Buffer.from(handshake.serverPublicKey, "base64"), clientNonce, Buffer.from(handshake.serverNonce, "base64"),
  );
  const sealedFor = (counter: number, request: object) => seal(
    keys.clientToServer, Buffer.from(JSON.stringify(request)), additionalData(handshake.channelId, "req", counter),
  );
  return {
    channelId: handshake.channelId, keys, sealedFor,
    async exchange(counter, request) {
      const reply = await app.inject({
        method: "POST", url: "/v1/secure/exchange",
        payload: {channelId: handshake.channelId, counter, payload: sealedFor(counter, request)},
      });
      return {statusCode: reply.statusCode, body: reply.json() as Record<string, unknown>};
    },
    decode: (counter, payload) => JSON.parse(open(
      keys.serverToClient, payload, additionalData(handshake.channelId, "res", counter),
    ).toString("utf8")),
  };
}

const get = (url: string, headers: Record<string, string> = {}) => ({method: "GET", url, headers, body: null});

test("eine verschlüsselte Anfrage erreicht die Route, die Antwort kommt verschlüsselt zurück", async () => {
  const {app} = await server();
  const client = await connect(app);

  const reply = await client.exchange(1, get("/v1/echo?a=1", {authorization: "Bearer geheimes-token"}));
  const inner = client.decode(1, reply.body.payload as string);

  assert.equal(reply.statusCode, 200);
  assert.equal(inner.status, 200);
  assert.deepEqual(JSON.parse(inner.body), {authorization: "Bearer geheimes-token", query: {a: "1"}});
});

test("im Netz sichtbar sind weder Token noch Pfad noch Inhalt", async () => {
  const {app} = await server();
  const client = await connect(app);
  const sent = client.sealedFor(1, get("/v1/echo?secret=abc", {authorization: "Bearer geheimes-token"}));
  const reply = await client.exchange(2, get("/v1/echo", {authorization: "Bearer geheimes-token"}));

  const visible = JSON.stringify({sent, received: reply.body});
  for (const secret of ["geheimes-token", "echo", "secret", "Bearer"]) {
    assert.ok(!Buffer.from(sent, "base64").toString("latin1").includes(secret), `Anfrage verrät ${secret}`);
    assert.ok(!visible.includes(secret), `Sichtbarer Verkehr verrät ${secret}`);
  }
});

test("POST mit Body und Statuscode der Route bleiben erhalten", async () => {
  const {app} = await server();
  const client = await connect(app);

  const reply = await client.exchange(1, {
    method: "POST", url: "/v1/items", headers: {"content-type": "application/json"}, body: JSON.stringify({name: "Bericht"}),
  });
  const inner = client.decode(1, reply.body.payload as string);

  assert.equal(inner.status, 201);
  assert.deepEqual(JSON.parse(inner.body), {received: {name: "Bericht"}});
});

test("eine wiederholte Anfrage wird abgelehnt, auch parallel", async () => {
  const {app} = await server();
  const client = await connect(app);
  const payload = client.sealedFor(1, get("/v1/echo"));
  const send = () => app.inject({method: "POST", url: "/v1/secure/exchange", payload: {channelId: client.channelId, counter: 1, payload}});

  const results = await Promise.all([send(), send(), send()]);
  const later = await send();

  assert.deepEqual(results.map((result) => result.statusCode).sort(), [200, 409, 409]);
  assert.equal(later.statusCode, 409);
  assert.equal((later.json() as {code: string}).code, "secure_replay");
});

test("Anfragen dürfen sich überholen, zu alte Zähler nicht", async () => {
  const {app} = await server();
  const client = await connect(app);

  assert.equal((await client.exchange(10, get("/v1/echo"))).statusCode, 200);
  assert.equal((await client.exchange(9, get("/v1/echo"))).statusCode, 200);
  assert.equal((await client.exchange(300, get("/v1/echo"))).statusCode, 200);
  assert.equal((await client.exchange(10, get("/v1/echo"))).statusCode, 409);
  assert.equal((await client.exchange(100, get("/v1/echo"))).statusCode, 409, "außerhalb des Fensters");
});

test("ein manipulierter Umschlag oder verschobener Zähler wird abgelehnt und verbraucht keinen Zähler", async () => {
  const {app} = await server();
  const client = await connect(app);
  const valid = client.sealedFor(1, get("/v1/echo"));
  const tampered = Buffer.from(valid, "base64");
  tampered[tampered.length - 1] ^= 1;
  const post = (counter: number, payload: string) => app.inject({
    method: "POST", url: "/v1/secure/exchange", payload: {channelId: client.channelId, counter, payload},
  });

  assert.equal((await post(1, tampered.toString("base64"))).statusCode, 400);
  assert.equal((await post(2, valid)).statusCode, 400, "Zähler ist Teil der Zusatzdaten");
  assert.equal((await post(1, valid)).statusCode, 200);
});

test("ein unbekannter oder abgelaufener Kanal liefert 404, damit der Client neu verhandelt", async () => {
  let clock = 1_000;
  const {app} = await server(new SecureChannelStore({idleMilliseconds: 100, now: () => clock}));
  const client = await connect(app);
  clock += 500;

  const expired = await client.exchange(1, get("/v1/echo"));
  const unknown = await app.inject({
    method: "POST", url: "/v1/secure/exchange", payload: {channelId: "gibt-es-nicht", counter: 1, payload: "AAAA"},
  });

  assert.equal(expired.statusCode, 404);
  assert.equal((expired.body as {code: string}).code, "secure_channel_unknown");
  assert.equal(unknown.statusCode, 404);
});

test("nur /v1-Endpunkte außer dem Tunnel selbst sind erreichbar", async () => {
  const {app} = await server();
  const client = await connect(app);

  let counter = 0;
  for (const url of ["/healthz", "/v1/secure/handshake", "/index.html", "/v1/../healthz"]) {
    const reply = await client.exchange(++counter, get(url));
    assert.equal(reply.statusCode, 400, url);
    assert.equal((reply.body as {code: string}).code, "secure_forbidden", url);
  }
  const method = await client.exchange(++counter, {method: "TRACE", url: "/v1/echo", headers: {}, body: null});
  assert.equal(method.statusCode, 400);
});

test("nicht-JSON-Antworten gehen nicht durch den Tunnel", async () => {
  const {app} = await server();
  const client = await connect(app);

  const reply = await client.exchange(1, get("/v1/binary"));

  assert.equal(client.decode(1, reply.body.payload as string).status, 415);
});

test("der Handshake prüft Länge von Schlüssel und Nonce", async () => {
  const {app} = await server();

  const reply = await app.inject({
    method: "POST", url: "/v1/secure/handshake",
    payload: {clientPublicKey: Buffer.alloc(10).toString("base64"), clientNonce: Buffer.alloc(16).toString("base64")},
  });

  assert.equal(reply.statusCode, 400);
  assert.equal((reply.json() as {code: string}).code, "secure_invalid");
});

test("der Speicher begrenzt die Zahl der Kanäle und verwirft die ältesten", async () => {
  let clock = 0;
  const {app, store} = await server(new SecureChannelStore({maxChannels: 2, now: () => ++clock}));

  const first = await connect(app);
  await connect(app);
  await connect(app);

  assert.equal(store.size, 2);
  assert.equal(store.find(first.channelId), undefined);
});
