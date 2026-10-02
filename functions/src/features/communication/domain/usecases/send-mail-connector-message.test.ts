import assert from "node:assert/strict";
import test from "node:test";
import {type MailConnectorRepository} from "../repositories/mail-connector-repository.js";
import {type MailProvider} from "../repositories/mail-provider.js";
import {sendMailConnectorMessage} from "./send-mail-connector-message.js";

test("sends through an active connector and persists the refreshed token", async () => {
  const repository = activeRepository();
  const provider = sendingProvider();

  await sendMailConnectorMessage({
    teamId: "team-1",
    connectorId: "connector-1",
    recipient: "customer@example.com",
    subject: "Antwort",
    body: "Danke.",
    repository,
    provider,
  });

  assert.deepEqual(provider.sent, [{
    accessToken: "access-token",
    recipient: "customer@example.com",
    subject: "Antwort",
    body: "Danke.",
  }]);
  assert.equal(repository.updatedRefreshToken, "new-refresh-token");
});

function activeRepository(): MailConnectorRepository & {updatedRefreshToken: string} {
  const repository = {
    updatedRefreshToken: "",
    async loadConnector() {
      return {
        connector: {
          id: "connector-1", teamId: "team-1", createdByUid: "user-1",
          provider: "microsoftGraph" as const, emailAddress: "team@example.com",
          displayName: "Team", status: "active" as const,
          subscriptionId: "subscription-1", subscriptionExpiresAt: new Date(),
          createdAt: new Date(), updatedAt: new Date(),
        },
        credentials: {refreshToken: "old-refresh-token", subscriptionClientState: "state"},
      };
    },
    async updateCredentials(input: {credentials: {refreshToken: string}}) {
      repository.updatedRefreshToken = input.credentials.refreshToken;
    },
  };
  return repository as unknown as MailConnectorRepository & {updatedRefreshToken: string};
}

function sendingProvider(): MailProvider & {sent: Array<Record<string, string>>} {
  const provider = {
    provider: "microsoftGraph" as const,
    sent: [] as Array<Record<string, string>>,
    async refreshAccessToken() {
      return {accessToken: "access-token", refreshToken: "new-refresh-token"};
    },
    async sendMessage(input: Record<string, string>) {
      provider.sent.push(input);
    },
  };
  return provider as unknown as MailProvider & {sent: Array<Record<string, string>>};
}

test("a connector that needs reauthorization is rejected with a dedicated error", async () => {
  const { MemoryMailConnectorRepository, ScriptedMailProvider } = await import("../services/mail-connector-test-support.js");
  const { MailReauthorizationRequiredError } = await import("../services/mail-connector-token-service.js");
  const repository = new MemoryMailConnectorRepository({status: "reauthorizationRequired"});
  const provider = new ScriptedMailProvider();

  await assert.rejects(
    sendMailConnectorMessage({
      teamId: "team-1", connectorId: "connector-1", recipient: "a@example.com", subject: "S", body: "B",
      repository: repository.asRepository(), provider: provider.asProvider(),
    }),
    MailReauthorizationRequiredError,
  );
  assert.equal(provider.refreshCalls.length, 0);
});

test("an expired token during sending marks the connector and fails without sending", async () => {
  const { MemoryMailConnectorRepository, ScriptedMailProvider, invalidGrant } = await import("../services/mail-connector-test-support.js");
  const { MailReauthorizationRequiredError } = await import("../services/mail-connector-token-service.js");
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider(() => invalidGrant());

  await assert.rejects(
    sendMailConnectorMessage({
      teamId: "team-1", connectorId: "connector-1", recipient: "a@example.com", subject: "S", body: "B",
      repository: repository.asRepository(), provider: provider.asProvider(),
    }),
    MailReauthorizationRequiredError,
  );
  assert.equal(repository.status, "reauthorizationRequired");
  assert.equal(provider.sent.length, 0);
});

test("a rejected access token is refreshed once and the message is still sent", async () => {
  const { MemoryMailConnectorRepository, ScriptedMailProvider, unauthorized } = await import("../services/mail-connector-test-support.js");
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  provider.sendFailures.push(unauthorized());

  await sendMailConnectorMessage({
    teamId: "team-1", connectorId: "connector-1", recipient: "a@example.com", subject: "S", body: "B",
    repository: repository.asRepository(), provider: provider.asProvider(),
  });

  assert.deepEqual(provider.sent.map((message) => message.accessToken), ["access-2"]);
});
