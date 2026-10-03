import assert from "node:assert/strict";
import test from "node:test";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {MailConnectorListCache} from "./mail-connector-list-cache.js";
import {MAIL_CONNECTORS_TOPIC, RuntimeWakeupHandler} from "./runtime-wakeup-handler.js";

const license: SignedRuntimeLicense = {
  signature: "sig",
  payload: {licenseId: "l", licenseName: "n", activationId: "a", workspaceId: "w", issuedAt: "2026-01-01", expiresAt: "2027-01-01"},
};

function setup() {
  const cache = new MailConnectorListCache();
  const events = {mail: 0, topics: [] as string[], loads: 0};
  const handler = new RuntimeWakeupHandler(
    () => { events.mail++; }, cache, (topic) => events.topics.push(topic),
  );
  const load = async () => { events.loads++; return []; };
  return {cache, events, handler, load};
}

test("der erste Stand holt Mails, meldet aber keine Änderung der Postfachliste", () => {
  const {events, handler} = setup();

  handler.handle({communicationRevision: 3, connectorsRevision: 2});

  assert.equal(events.mail, 1);
  assert.deepEqual(events.topics, []);
});

test("eine neue Mail holt Mails, lässt die Postfachliste aber stehen", async () => {
  const {cache, events, handler, load} = setup();
  handler.handle({communicationRevision: 1, connectorsRevision: 1});
  await cache.list(license, load);

  handler.handle({communicationRevision: 2, connectorsRevision: 1});
  await cache.list(license, load);

  assert.equal(events.mail, 2);
  assert.equal(events.loads, 1);
  assert.deepEqual(events.topics, []);
});

test("eine geänderte Postfachliste leert den Cache und meldet den Clients den Kanal", async () => {
  const {cache, events, handler, load} = setup();
  handler.handle({communicationRevision: 1, connectorsRevision: 1});
  await cache.list(license, load);

  handler.handle({communicationRevision: 1, connectorsRevision: 2});
  await cache.list(license, load);

  assert.equal(events.mail, 1);
  assert.equal(events.loads, 2);
  assert.deepEqual(events.topics, [MAIL_CONNECTORS_TOPIC]);
});

test("ein erstmals auftauchendes connectorsRevision nach dem Start zählt als Änderung", () => {
  const {events, handler} = setup();
  handler.handle({communicationRevision: 1});

  handler.handle({communicationRevision: 1, connectorsRevision: 1});

  assert.deepEqual(events.topics, [MAIL_CONNECTORS_TOPIC]);
});

test("scheitert der Listener, wird nichts Gecachtes behalten und der Kanal gemeldet", async () => {
  const {cache, events, handler, load} = setup();
  await cache.list(license, load);

  handler.handleFailure();
  await cache.list(license, load);

  assert.equal(events.loads, 2);
  assert.deepEqual(events.topics, [MAIL_CONNECTORS_TOPIC]);
});
