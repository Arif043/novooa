import assert from "node:assert/strict";
import test from "node:test";
import {type MailConnector} from "../entities/mail-connector.js";
import {type MailConnectorRepository} from "../repositories/mail-connector-repository.js";
import {type MailProvider} from "../repositories/mail-provider.js";
import {completeMailConnectorAuthorization} from "./complete-mail-connector-authorization.js";

function fakes(existing: MailConnector | null) {
  const created: Array<{connector: MailConnector; credentials: {refreshToken: string; subscriptionClientState: string}}> = [];
  const repository = {
    async consumeAuthorization() {
      return {
        id: "auth-1", teamId: "team-1", uid: "user-2", provider: "microsoftGraph", codeVerifier: "verifier",
        runtimeLicenseId: "lizenz-1", expiresAt: new Date(Date.now() + 60_000),
      };
    },
    async findConnectorByEmailAddress() {
      return existing;
    },
    async createConnector(input: (typeof created)[number]) {
      created.push(input);
    },
  } as unknown as MailConnectorRepository;
  const provider = {
    provider: "microsoftGraph",
    async exchangeAuthorizationCode() {
      return {accessToken: "access", refreshToken: "neues-refresh-token"};
    },
    async loadProfile() {
      return {emailAddress: "team@example.com", displayName: "Team Postfach"};
    },
    async createMessageSubscription() {
      return {id: "neue-subscription", expiresAt: new Date(Date.now() + 86_400_000)};
    },
  } as unknown as MailProvider;
  return {repository, provider, created};
}

const input = (repository: MailConnectorRepository, provider: MailProvider) => ({
  authorizationId: "auth-1", authorizationCode: "code", connectorId: "neue-id",
  subscriptionClientState: "neuer-client-state", repository, provider, now: new Date("2026-10-02T10:00:00Z"),
});

test("ein neues Postfach bekommt einen neuen Connector", async () => {
  const {repository, provider, created} = fakes(null);

  const connector = await completeMailConnectorAuthorization(input(repository, provider));

  assert.equal(connector.id, "neue-id");
  assert.equal(connector.createdByUid, "user-2");
  assert.equal(connector.status, "active");
  assert.equal(created.length, 1);
});

test("erneutes Verbinden behält ID und Erstellungsdaten und aktiviert den Connector wieder", async () => {
  const existing: MailConnector = {
    id: "alte-id", teamId: "team-1", createdByUid: "user-1", provider: "microsoftGraph",
    runtimeLicenseId: "lizenz-1", emailAddress: "team@example.com", displayName: "Alt", status: "reauthorizationRequired",
    subscriptionId: "alte-subscription", subscriptionExpiresAt: new Date(0),
    createdAt: new Date("2026-01-01T00:00:00Z"), updatedAt: new Date("2026-01-01T00:00:00Z"),
  };
  const {repository, provider, created} = fakes(existing);

  const connector = await completeMailConnectorAuthorization(input(repository, provider));

  assert.equal(connector.id, "alte-id");
  assert.equal(connector.createdByUid, "user-1");
  assert.equal(connector.createdAt.toISOString(), "2026-01-01T00:00:00.000Z");
  assert.equal(connector.status, "active");
  assert.equal(connector.subscriptionId, "neue-subscription");
  assert.equal(connector.displayName, "Team Postfach");
  assert.equal(created[0].credentials.refreshToken, "neues-refresh-token");
  assert.equal(created[0].credentials.subscriptionClientState, "neuer-client-state");
});
