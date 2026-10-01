import {testingRoutes} from "./local-runtime-http-test-support.js";
import assert from "node:assert/strict";
import test from "node:test";
import {LocalRuntimeSetupHttpHandler} from "./local-runtime-setup-http-handler.js";
import {
  type LocalRuntimeAccessCredentialStore,
  RuntimeAccessCredentialAlreadySetError,
} from "./local-runtime-access-credential-store.js";
import {type TestRequest as LocalRuntimeRequest} from "./local-runtime-http-test-support.js";

// Einmaliges Setzen des Betreiber-Passworts über den regulären Port. Als
// Nachweis dient der Lizenz-Token, mit dem die Runtime aktiviert wurde.

const redeemedToken = "A3K9N7P2Q4R6T8W5";

function handlerFor(credentials: FakeCredentialStore, requiresToken = true) {
  return testingRoutes(new LocalRuntimeSetupHttpHandler({
    credentials: credentials as unknown as LocalRuntimeAccessCredentialStore,
    authorization: {
      requiresActivationTokenForSetup: () => requiresToken,
      matchesActivationToken: (token) => token === redeemedToken,
    },
  }));
}

function postRequest(body: unknown): LocalRuntimeRequest {
  return {method: "POST", url: "/v1/setup", body} as LocalRuntimeRequest;
}

test("der Lizenz-Token der Aktivierung setzt das Passwort", async () => {
  const credentials = new FakeCredentialStore();

  const response = await handlerFor(credentials).handle(
    postRequest({password: "geheim", activationToken: redeemedToken}),
  );

  assert.equal(response?.statusCode, 204);
  assert.equal(credentials.password, "geheim");
});

test("ein fremder Lizenz-Token setzt kein Passwort", async () => {
  const credentials = new FakeCredentialStore();

  const response = await handlerFor(credentials).handle(
    postRequest({password: "geheim", activationToken: "B3K9N7P2Q4R6T8W5"}),
  );

  assert.equal(response?.statusCode, 403);
  assert.equal(credentials.password, null);
});

test("ohne Lizenz-Token wird kein Passwort gesetzt", async () => {
  const credentials = new FakeCredentialStore();

  const response = await handlerFor(credentials).handle(postRequest({password: "geheim"}));

  assert.equal(response?.statusCode, 403);
  assert.equal(credentials.password, null);
});

test("der Token wird geprüft, bevor das Passwort validiert wird", async () => {
  const response = await handlerFor(new FakeCredentialStore()).handle(
    postRequest({activationToken: "falsch"}),
  );

  assert.equal(response?.statusCode, 403, "kein 400 — verrät nichts über das Passwortfeld");
});

test("im Entwicklungsmodus ohne echte Lizenz genügt das Passwort", async () => {
  const credentials = new FakeCredentialStore();

  const response = await handlerFor(credentials, false).handle(postRequest({password: "geheim"}));

  assert.equal(response?.statusCode, 204);
});

test("ein bereits gesetztes Passwort bleibt unveränderbar", async () => {
  const credentials = new FakeCredentialStore();
  credentials.alreadySet = true;
  const response = await handlerFor(credentials).handle(
    postRequest({password: "neu", activationToken: redeemedToken}),
  );

  assert.equal(response?.statusCode, 409);
});

test("GET meldet den Bedarf, den Token-Nachweis und erreichbare Adressen", async () => {
  const response = await handlerFor(new FakeCredentialStore()).handle({
    method: "GET",
    url: "/v1/setup",
    headers: {host: "192.168.1.42:8090"},
  } as unknown as LocalRuntimeRequest);

  const body = response?.body as Record<string, unknown>;
  assert.equal(response?.statusCode, 200);
  assert.equal(body.needsSetup, true);
  assert.equal(body.requiresLicenseToken, true);
  assert.ok(Array.isArray(body.addresses));
  for (const address of body.addresses as string[]) {
    assert.match(address, /^http:\/\/.+:8090$/, "übernimmt den Port aus dem Host-Header");
  }
});

test("fremde Pfade gehen an den nächsten Handler weiter", async () => {
  const response = await handlerFor(new FakeCredentialStore()).handle({
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
