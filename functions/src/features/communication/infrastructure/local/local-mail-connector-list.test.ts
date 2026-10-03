import assert from "node:assert/strict";
import test, {afterEach} from "node:test";
import {testingRoutes, testWorkspace} from "../../../../shared/local/local-runtime-http-test-support.js";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {MailConnectorListCache} from "./mail-connector-list-cache.js";
import {mailRelayRoutes} from "./local-mail-relay-routes.js";
import {HttpRuntimeMailRelayClient} from "./runtime-mail-relay-client.js";

const license: SignedRuntimeLicense = {
  signature: "sig",
  payload: {licenseId: "l", licenseName: "n", activationId: "a", workspaceId: "w", issuedAt: "2026-01-01", expiresAt: "2027-01-01"},
};
const originalFetch = globalThis.fetch;
afterEach(() => {
  globalThis.fetch = originalFetch;
});

function relayReturning(items: unknown[]) {
  return {
    async beginMicrosoftAuthorization() { return {authorizationUrl: "https://login.example"}; },
    async listConnectors() { return items as never; },
    async listDeadLetters() { return []; },
    async replayDeadLetter() {},
  };
}

test("GET /v1/mail-connectors liefert die Postfächer dieser Runtime", async () => {
  const connector = {id: "c1", teamId: "w", emailAddress: "team@example.com", displayName: "Team", status: "active"};
  const routes = testingRoutes(mailRelayRoutes, {signedLicense: () => license, relay: relayReturning([connector]), connectorCache: new MailConnectorListCache()}, testWorkspace());

  const response = await routes.handle({method: "GET", url: "/v1/mail-connectors", body: {}});

  assert.equal(response?.statusCode, 200);
  assert.deepEqual(response?.body, {items: [connector]});
});

test("ohne aktive Lizenz gibt es keine Postfach-Liste", async () => {
  const routes = testingRoutes(mailRelayRoutes, {signedLicense: () => null, relay: relayReturning([]), connectorCache: new MailConnectorListCache()}, testWorkspace());

  const response = await routes.handle({method: "GET", url: "/v1/mail-connectors", body: {}});

  assert.notEqual(response?.statusCode, 200);
});

test("der Relay-Client fragt die Postfächer mit der Lizenz an und prüft die Antwort", async () => {
  const requests: unknown[] = [];
  globalThis.fetch = (async (_url: unknown, init: {body: string}) => {
    requests.push(JSON.parse(init.body));
    return new Response(JSON.stringify({items: [
      {id: "c1", teamId: "w", emailAddress: "a@example.com", displayName: "A", status: "active"},
      {id: "c2", teamId: "w", emailAddress: "b@example.com", displayName: "B", status: "etwas-unbekanntes"},
    ]}), {status: 200, headers: {"content-type": "application/json"}});
  }) as typeof fetch;
  const client = new HttpRuntimeMailRelayClient("https://relay.example/mail");

  const connectors = await client.listConnectors(license);

  assert.deepEqual(requests, [{type: "listMailConnectors", license}]);
  assert.deepEqual(connectors.map((connector) => connector.status), ["active", "disconnected"]);
});

test("der Relay-Client lehnt eine ungültige Antwort ab", async () => {
  globalThis.fetch = (async () => new Response(JSON.stringify({items: "kaputt"}), {status: 200}));
  const client = new HttpRuntimeMailRelayClient("https://relay.example/mail");

  await assert.rejects(client.listConnectors(license), /ungültige Postfächer/);
});
