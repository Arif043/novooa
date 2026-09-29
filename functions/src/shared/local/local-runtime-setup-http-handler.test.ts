import assert from "node:assert/strict";
import test from "node:test";
import {LocalRuntimeSetupHttpHandler} from "./local-runtime-setup-http-handler.js";
import {LocalRuntimeSetupCode} from "./local-runtime-setup-code.js";
import {
  type LocalRuntimeAccessCredentialStore,
  RuntimeAccessCredentialAlreadySetError,
} from "./local-runtime-access-credential-store.js";
import {type LocalRuntimeRequest} from "./local-runtime-http-server.js";

// Einmaliges Setzen des Betreiber-Passworts über den regulären Port, mit
// dem Kopplungscode aus dem Start-Log als Schutz. Der frühere zweite,
// loopback-gebundene Weg ohne Code ist entfernt: Ein verlorener Code lässt
// sich per `docker compose restart` jederzeit neu erzeugen — derselbe
// Vertrauensanker (Host-Zugriff), den auch der Loopback-Port vorausgesetzt
// hätte.

function handlerFor(credentials: FakeCredentialStore) {
  const setupCode = new LocalRuntimeSetupCode(() => "abc123abc123");
  const handler = new LocalRuntimeSetupHttpHandler({
    credentials: credentials as unknown as LocalRuntimeAccessCredentialStore,
    setupCode,
  });
  return {handler, setupCode};
}

function postRequest(body: unknown): LocalRuntimeRequest {
  return {method: "POST", url: "/v1/setup", body} as LocalRuntimeRequest;
}

test("richtiger Code setzt das Passwort", async () => {
  const credentials = new FakeCredentialStore();
  const {handler, setupCode} = handlerFor(credentials);

  const response = await handler.handle(
    postRequest({password: "geheim", code: "abc123abc123"}),
  );

  assert.equal(response?.statusCode, 204);
  assert.equal(credentials.password, "geheim");
  assert.equal(setupCode.current, null, "Code verfällt nach der Einrichtung");
});

test("falscher Code setzt kein Passwort", async () => {
  const credentials = new FakeCredentialStore();
  const {handler} = handlerFor(credentials);

  const response = await handler.handle(
    postRequest({password: "geheim", code: "falschfalsch"}),
  );

  assert.equal(response?.statusCode, 403);
  assert.equal(credentials.password, null);
});

test("fehlender Code setzt kein Passwort", async () => {
  const credentials = new FakeCredentialStore();
  const {handler} = handlerFor(credentials);

  const response = await handler.handle(postRequest({password: "geheim"}));

  assert.equal(response?.statusCode, 403);
  assert.equal(credentials.password, null);
});

test("der Code wird geprüft, bevor das Passwort validiert wird", async () => {
  const credentials = new FakeCredentialStore();
  const {handler} = handlerFor(credentials);

  const response = await handler.handle(postRequest({code: "falschfalsch"}));

  assert.equal(response?.statusCode, 403, "kein 400 — verrät nichts über das Passwortfeld");
});

test("ein verbrauchter Code wird abgelehnt", async () => {
  const credentials = new FakeCredentialStore();
  const {handler, setupCode} = handlerFor(credentials);
  setupCode.consume();

  const response = await handler.handle(
    postRequest({password: "geheim", code: "abc123abc123"}),
  );

  assert.equal(response?.statusCode, 403);
  assert.equal(credentials.password, null);
});

test("ein bereits gesetztes Passwort bleibt unveränderbar", async () => {
  const credentials = new FakeCredentialStore();
  credentials.alreadySet = true;
  const {handler} = handlerFor(credentials);

  const response = await handler.handle(
    postRequest({password: "neu", code: "abc123abc123"}),
  );

  assert.equal(response?.statusCode, 409);
});

test("GET meldet den Bedarf und erreichbare Adressen", async () => {
  const credentials = new FakeCredentialStore();
  const {handler} = handlerFor(credentials);

  const response = await handler.handle({
    method: "GET",
    url: "/v1/setup",
    headers: {host: "192.168.1.42:8090"},
  } as unknown as LocalRuntimeRequest);

  const body = response?.body as Record<string, unknown>;
  assert.equal(response?.statusCode, 200);
  assert.equal(body.needsSetup, true);
  assert.ok(Array.isArray(body.addresses));
  for (const address of body.addresses as string[]) {
    assert.match(address, /^http:\/\/.+:8090$/, "übernimmt den Port aus dem Host-Header");
  }
});

test("fremde Pfade gehen an den nächsten Handler weiter", async () => {
  const credentials = new FakeCredentialStore();
  const {handler} = handlerFor(credentials);

  const response = await handler.handle({
    method: "GET",
    url: "/v1/tasks",
  } as LocalRuntimeRequest);

  assert.equal(response, null);
});

class FakeCredentialStore {
  password: string | null = null;
  alreadySet = false;

  async hasCredential(): Promise<boolean> {
    return this.alreadySet || this.password !== null;
  }

  async setPassword(password: string): Promise<void> {
    if (await this.hasCredential()) {
      throw new RuntimeAccessCredentialAlreadySetError();
    }
    this.password = password;
  }
}
