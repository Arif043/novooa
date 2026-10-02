import assert from "node:assert/strict";
import test from "node:test";
import {MailReauthorizationRequiredError} from "../services/mail-connector-token-service.js";
import {
  invalidGrant,
  MemoryMailConnectorRepository,
  notFound,
  ScriptedMailProvider,
  serverError,
} from "../services/mail-connector-test-support.js";
import {handleMailSubscriptionLifecycle} from "./handle-mail-subscription-lifecycle.js";
import {recreateMailConnectorSubscription, renewMailConnectorSubscription} from "./renew-mail-connector-subscription.js";

function inputFor(repository: MemoryMailConnectorRepository, provider: ScriptedMailProvider) {
  return {...repository.connection(), repository: repository.asRepository(), provider: provider.asProvider()};
}

test("verlängert eine laufende Subscription und speichert das neue Ablaufdatum", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  const before = repository.subscription.expiresAt as Date;

  const outcome = await renewMailConnectorSubscription(inputFor(repository, provider));

  assert.equal(outcome, "renewed");
  assert.deepEqual(provider.renewCalls, ["access-1:subscription-1"]);
  assert.equal(provider.createCalls.length, 0);
  assert.ok((repository.subscription.expiresAt as Date) > before);
  assert.equal(repository.refreshToken, "refresh-2", "rotiertes Refresh Token gespeichert");
});

test("legt eine neue Subscription an, wenn die alte abgelaufen ist", async () => {
  const repository = new MemoryMailConnectorRepository();
  repository.subscription = {id: "alt", expiresAt: new Date(Date.now() - 1000)};
  const provider = new ScriptedMailProvider();

  const outcome = await renewMailConnectorSubscription(inputFor(repository, provider));

  assert.equal(outcome, "recreated");
  assert.equal(provider.renewCalls.length, 0, "eine abgelaufene wird nicht erst verlängert");
  assert.deepEqual(provider.createCalls, ["access-1:client-state"]);
  assert.equal(repository.subscription.id, "new-subscription-1");
});

test("legt eine neue an, wenn der Anbieter die Subscription nicht (mehr) kennt", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  provider.renewError = notFound();

  const outcome = await renewMailConnectorSubscription(inputFor(repository, provider));

  assert.equal(outcome, "recreated");
  assert.equal(repository.subscription.id, "new-subscription-1");
});

test("legt eine an, wenn der Connector noch keine hat", async () => {
  const repository = new MemoryMailConnectorRepository();
  repository.subscription = {id: null, expiresAt: null};
  const provider = new ScriptedMailProvider();

  assert.equal(await renewMailConnectorSubscription(inputFor(repository, provider)), "recreated");
});

test("andere Fehler beim Verlängern führen nicht zu einer neuen Subscription", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  provider.renewError = serverError();

  await assert.rejects(renewMailConnectorSubscription(inputFor(repository, provider)), /temporarily_unavailable/);

  assert.equal(provider.createCalls.length, 0);
  assert.equal(repository.subscription.id, "subscription-1");
});

test("eine ungültige Anmeldung setzt den Status und legt nichts an", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider(() => invalidGrant());

  await assert.rejects(renewMailConnectorSubscription(inputFor(repository, provider)), MailReauthorizationRequiredError);

  assert.equal(repository.status, "reauthorizationRequired");
  assert.equal(provider.renewCalls.length + provider.createCalls.length, 0);
});

test("recreate legt immer eine neue Subscription an", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();

  assert.equal(await recreateMailConnectorSubscription(inputFor(repository, provider)), "recreated");
  assert.equal(provider.renewCalls.length, 0);
  assert.equal(repository.subscription.id, "new-subscription-1");
});

test("Lifecycle reauthorizationRequired verlängert die Subscription", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();

  const outcome = await handleMailSubscriptionLifecycle({...inputFor(repository, provider), event: "reauthorizationRequired"});

  assert.equal(outcome, "renewed");
  assert.equal(provider.renewCalls.length, 1);
});

test("Lifecycle subscriptionRemoved legt eine neue Subscription an", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();

  const outcome = await handleMailSubscriptionLifecycle({...inputFor(repository, provider), event: "subscriptionRemoved"});

  assert.equal(outcome, "recreated");
  assert.equal(repository.subscription.id, "new-subscription-1");
});

test("Lifecycle missed und Unbekanntes bleiben ohne Wirkung", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();

  for (const event of ["missed", "etwasNeues"]) {
    assert.equal(await handleMailSubscriptionLifecycle({...inputFor(repository, provider), event}), "ignored");
  }
  assert.equal(provider.refreshCalls.length, 0);
});

test("Lifecycle meldet eine ungültige Anmeldung ohne Fehler, damit die Warteschlange nicht wiederholt", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider(() => invalidGrant());

  const outcome = await handleMailSubscriptionLifecycle({...inputFor(repository, provider), event: "reauthorizationRequired"});

  assert.equal(outcome, "reauthorizationRequired");
  assert.equal(repository.status, "reauthorizationRequired");
});

test("Lifecycle reicht vorübergehende Fehler weiter, damit die Warteschlange wiederholt", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider(() => serverError());

  await assert.rejects(
    handleMailSubscriptionLifecycle({...inputFor(repository, provider), event: "subscriptionRemoved"}),
    /temporarily_unavailable/,
  );
});
