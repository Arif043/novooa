import assert from "node:assert/strict";
import test from "node:test";
import {LocalRuntimeSessionAuthMiddleware} from "./local-runtime-session-auth-middleware.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
  type LocalRuntimeStreamRequest,
} from "./local-runtime-http-server.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

// Deckt die Regression ab, die einen Browser-Zugriff auf das von der
// Runtime ausgelieferte Web-Build unmöglich gemacht hat: Ein gewöhnlicher
// Seitenaufruf trägt nie einen `Authorization`-Header, den setzt erst der
// bereits laufende Dart-Client. Ohne Ausnahme für Nicht-`/v1/*`-Pfade käme
// die SPA nie über den 401 der Middleware hinaus, um sich selbst zu laden.
test("lässt Anfragen außerhalb von /v1/* ohne Token durch — die SPA muss sich laden können", async () => {
  const inner = new FakeHandler({body: {ok: true}, statusCode: 200});
  const middleware = new LocalRuntimeSessionAuthMiddleware(fakeSessions(false), inner);

  const response = await middleware.handle({body: {}, method: "GET", url: "/"});

  assert.deepEqual(response, {body: {ok: true}, statusCode: 200});
  assert.deepEqual(inner.receivedUrls, ["/"]);
});

test("lässt statische Web-Build-Dateien ohne Token durch", async () => {
  const inner = new FakeHandler({body: {ok: true}, statusCode: 200});
  const middleware = new LocalRuntimeSessionAuthMiddleware(fakeSessions(false), inner);

  await middleware.handle({body: {}, method: "GET", url: "/main.dart.js"});
  await middleware.handle({body: {}, method: "GET", url: "/manifest.json"});

  assert.deepEqual(inner.receivedUrls, ["/main.dart.js", "/manifest.json"]);
});

test("verlangt für /v1/*-Anfragen ohne Token eine Anmeldung", async () => {
  const inner = new FakeHandler({body: {ok: true}, statusCode: 200});
  const middleware = new LocalRuntimeSessionAuthMiddleware(fakeSessions(false), inner);

  const response = await middleware.handle({body: {}, method: "GET", url: "/v1/tasks"});

  assert.deepEqual(response, {body: {error: "Anmeldung erforderlich."}, statusCode: 401});
  assert.deepEqual(inner.receivedUrls, []);
});

test("lässt /v1/*-Anfragen mit gültigem Token durch", async () => {
  const inner = new FakeHandler({body: {ok: true}, statusCode: 200});
  const middleware = new LocalRuntimeSessionAuthMiddleware(fakeSessions(true), inner);

  const response = await middleware.handle({
    body: {}, method: "GET", url: "/v1/tasks", headers: {authorization: "Bearer valid-token"},
  });

  assert.deepEqual(response, {body: {ok: true}, statusCode: 200});
});

test("lässt /v1/auth/login und /v1/setup ohne Token durch — Henne-und-Ei", async () => {
  const inner = new FakeHandler({body: {ok: true}, statusCode: 200});
  const middleware = new LocalRuntimeSessionAuthMiddleware(fakeSessions(false), inner);

  await middleware.handle({body: {}, method: "POST", url: "/v1/auth/login"});
  await middleware.handle({body: {}, method: "POST", url: "/v1/setup"});

  assert.deepEqual(inner.receivedUrls, ["/v1/auth/login", "/v1/setup"]);
});

test("handleStream verlangt weiterhin unconditional eine Anmeldung", async () => {
  const inner = new FakeHandler({body: {ok: true}, statusCode: 200});
  const middleware = new LocalRuntimeSessionAuthMiddleware(fakeSessions(false), inner);

  const response = await middleware.handleStream({
    body: emptyStream(), headers: {}, method: "GET", url: "/v1/realtime",
  });

  assert.deepEqual(response, {body: {error: "Anmeldung erforderlich."}, statusCode: 401});
});

async function* emptyStream(): AsyncIterable<Uint8Array> {}

// `LocalRuntimeSessionStore` hat ein privates `database`-Feld, das eine
// echte SQLite-Anbindung voraussetzt — für diese Middleware-Tests genügt
// die öffentliche Oberfläche, deshalb der Cast statt einer echten Instanz.
function fakeSessions(valid: boolean): LocalRuntimeSessionStore {
  return {
    verifySession: async () => valid,
    createSession: async () => { throw new Error("nicht in diesem Test benötigt"); },
  } as unknown as LocalRuntimeSessionStore;
}

class FakeHandler implements LocalRuntimeRequestHandler {
  receivedUrls: string[] = [];
  constructor(private readonly response: LocalRuntimeResponse) {}
  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    this.receivedUrls.push(request.url ?? "");
    return this.response;
  }
  async handleStream(request: LocalRuntimeStreamRequest): Promise<LocalRuntimeResponse | null> {
    this.receivedUrls.push(request.url ?? "");
    return this.response;
  }
}
