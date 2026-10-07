import assert from "node:assert/strict";
import test from "node:test";
import {RuntimeAccessCredentialAlreadySetError} from "./local-runtime-access-credential-store.js";
import {type TestRequest, testingRoutes} from "./local-runtime-http-test-support.js";
import {setupRoutes} from "./local-runtime-setup-routes.js";

// Einmaliges Setzen des Betreiber-Passworts über den regulären Port. Als
// Nachweis dient der Lizenz-Token, mit dem die Runtime aktiviert wurde.

const redeemedToken = "A3K9N7P2Q4R6T8W5";

function handlerFor(credentials: FakeCredentialStore, requiresToken = true) {
  return testingRoutes(setupRoutes, {
    credentials,
    authorization: {
      requiresActivationTokenForSetup: () => requiresToken,
      matchesActivationToken: (token) => token === redeemedToken,
    },
  });
}

function postRequest(body: unknown): TestRequest {
  return {method: "POST", url: "/v1/setup", body};
}

test("der Lizenz-Token der Aktivierung setzt das Passwort", async () => {
  const credentials = new FakeCredentialStore();

  const response = await handlerFor(credentials).handle(postRequest({password: "geheim", activationToken: redeemedToken}));

  assert.equal(response?.statusCode, 204);
  assert.equal(credentials.password, "geheim");
});

test("ein fremder oder fehlender Lizenz-Token setzt kein Passwort", async () => {
  for (const body of [{password: "geheim", activationToken: "B3K9N7P2Q4R6T8W5"}, {password: "geheim"}]) {
    const credentials = new FakeCredentialStore();

    const response = await handlerFor(credentials).handle(postRequest(body));

    assert.equal(response?.statusCode, 403);
    assert.equal(credentials.password, null);
  }
});

test("ein fehlendes Passwort lehnt bereits das Schema ab", async () => {
  const response = await handlerFor(new FakeCredentialStore()).handle(postRequest({activationToken: redeemedToken}));

  assert.equal(response?.statusCode, 400);
  assert.deepEqual(response?.body, {error: "Ungültige Anfrage.", code: "invalid_request", field: "body"});
});

test("im Entwicklungsmodus ohne echte Lizenz genügt das Passwort", async () => {
  const response = await handlerFor(new FakeCredentialStore(), false).handle(postRequest({password: "geheim"}));

  assert.equal(response?.statusCode, 204);
});

test("ein bereits gesetztes Passwort bleibt unveränderbar", async () => {
  const credentials = new FakeCredentialStore();
  credentials.alreadySet = true;

  const response = await handlerFor(credentials).handle(postRequest({password: "neu", activationToken: redeemedToken}));

  assert.equal(response?.statusCode, 409);
});

test("GET meldet nur den Bedarf und den Token-Nachweis, keine Netzwerkadressen", async () => {
  const response = await handlerFor(new FakeCredentialStore()).handle({
    method: "GET", url: "/v1/setup", body: undefined, headers: {host: "192.168.1.42:8090"},
  });

  assert.deepEqual(response, {statusCode: 200, body: {needsSetup: true, requiresLicenseToken: true}});
});

test("fremde Pfade gehen an den nächsten Handler weiter", async () => {
  const response = await handlerFor(new FakeCredentialStore()).handle({method: "GET", url: "/v1/tasks", body: undefined});

  assert.equal(response, null);
});

class FakeCredentialStore {
  password: string | null = null;
  alreadySet = false;

  async hasCredential(): Promise<boolean> {
    return this.alreadySet || this.password !== null;
  }

  async setPassword(password: string): Promise<void> {
    if (await this.hasCredential()) throw new RuntimeAccessCredentialAlreadySetError();
    this.password = password;
  }
}
