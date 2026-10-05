import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {tasks} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {webhookSecretRef} from "../../domain/repositories/webhook-secret-store.js";
import {cycleGuardFor} from "../../domain/usecases/trigger-cycle-guard-test-support.js";
import {taskTriggerRoutes} from "./local-task-trigger-routes.js";
import {webhookSecretsFor} from "./webhook-secrets-test-support.js";

type Trigger = {id: string; eventConfig: {source: string; webhook?: {token: string; verification: {kind: string; header?: string}; validationParameter: string; secret?: string}}};
type Failure = {error?: string};

async function setup(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(tasks).values({id: "a", team_id: "team-1", title: "A", graph_json: "{}", created_by_uid: "u"});
  const secrets = webhookSecretsFor(database);
  const routes = testingRoutes(taskTriggerRoutes, {
    database, notifier: new LocalRuntimeRealtimeNotifier(), cycleGuard: cycleGuardFor(database), webhookSecrets: secrets,
  });
  async function call<T>(method: string, url: string, body: unknown = {}) {
    const response = await routes.handle({method, url, body});
    assert.ok(response);
    return {status: response.statusCode, body: response.body as T};
  }
  return {call, secrets};
}

const hmac = {kind: "hmac", header: "X-Signature", algorithm: "sha256", encoding: "hex", prefix: "sha256="};

function create(webhook: Record<string, unknown>) {
  return {taskId: "a", type: "event", eventConfig: {source: "webhookReceived", webhook}};
}

test("der Server vergibt das Token; ein vom Client gesendetes wird ignoriert", async (t) => {
  const {call} = await setup(t);
  const created = await call<Trigger>("POST", "/v1/task-triggers", create({token: "vorgegeben", verification: {kind: "none"}}));
  assert.equal(created.status, 201);
  const token = created.body.eventConfig.webhook?.token ?? "";
  assert.notEqual(token, "vorgegeben");
  assert.match(token, /^[A-Za-z0-9_-]{43}$/);
});

test("jedes Anlegen ergibt ein eigenes Token", async (t) => {
  const {call} = await setup(t);
  const first = await call<Trigger>("POST", "/v1/task-triggers", create({}));
  const second = await call<Trigger>("POST", "/v1/task-triggers", create({}));
  assert.notEqual(first.body.eventConfig.webhook?.token, second.body.eventConfig.webhook?.token);
});

test("eine Signaturprüfung braucht ein Geheimnis, das verschlüsselt abgelegt und nie ausgeliefert wird", async (t) => {
  const {call, secrets} = await setup(t);
  const without = await call<Failure>("POST", "/v1/task-triggers", create({verification: hmac}));
  assert.equal(without.status, 400);
  assert.match(without.body.error ?? "", /Geheimnis/);

  const created = await call<Trigger>("POST", "/v1/task-triggers", create({verification: hmac, secret: "geheim-123"}));
  assert.equal(created.status, 201);
  assert.equal(created.body.eventConfig.webhook?.verification.header, "x-signature");
  assert.equal(await secrets.read(webhookSecretRef("team-1", created.body.id)), "geheim-123");

  const listed = await call<{items: Trigger[]}>("GET", "/v1/task-triggers");
  assert.equal(JSON.stringify([created.body, listed.body]).includes("geheim-123"), false);
});

test("ein Geheimnis ohne Signaturprüfung wird nicht gespeichert", async (t) => {
  const {call, secrets} = await setup(t);
  const created = await call<Trigger>("POST", "/v1/task-triggers", create({verification: {kind: "none"}, secret: "unnötig"}));
  assert.equal(await secrets.read(webhookSecretRef("team-1", created.body.id)), null);
});

test("ungültige Namen werden abgelehnt", async (t) => {
  const {call} = await setup(t);
  const header = await call<Failure>("POST", "/v1/task-triggers", create({verification: {...hmac, header: "Ungültig Name"}, secret: "x"}));
  const parameter = await call<Failure>("POST", "/v1/task-triggers", create({validationParameter: "a b"}));
  assert.equal(header.status, 400);
  assert.equal(parameter.status, 400);
});

test("das Einrichtungs-Parametername wird übernommen", async (t) => {
  const {call} = await setup(t);
  const created = await call<Trigger>("POST", "/v1/task-triggers", create({validationParameter: "validationToken"}));
  assert.equal(created.body.eventConfig.webhook?.validationParameter, "validationToken");
});

test("das Token lässt sich erneuern, die übrige Konfiguration bleibt", async (t) => {
  const {call} = await setup(t);
  const created = await call<Trigger>("POST", "/v1/task-triggers", create({validationParameter: "validationToken"}));
  const rotated = await call<Trigger>("POST", `/v1/task-triggers/${created.body.id}/webhook-token`);
  assert.equal(rotated.status, 200);
  assert.notEqual(rotated.body.eventConfig.webhook?.token, created.body.eventConfig.webhook?.token);
  assert.equal(rotated.body.eventConfig.webhook?.validationParameter, "validationToken");
});

test("die Erneuerung betrifft nur Webhook-Auslöser", async (t) => {
  const {call} = await setup(t);
  const file = await call<Trigger>("POST", "/v1/task-triggers", {taskId: "a", type: "event", eventConfig: {source: "fileCreated"}});
  assert.equal(file.body.eventConfig.webhook, undefined);
  assert.equal((await call("POST", `/v1/task-triggers/${file.body.id}/webhook-token`)).status, 404);
  assert.equal((await call("POST", "/v1/task-triggers/gibt-es-nicht/webhook-token")).status, 404);
});

test("beim Löschen verschwindet auch das Geheimnis", async (t) => {
  const {call, secrets} = await setup(t);
  const created = await call<Trigger>("POST", "/v1/task-triggers", create({verification: hmac, secret: "geheim"}));
  await call("DELETE", `/v1/task-triggers/${created.body.id}`);
  assert.equal(await secrets.read(webhookSecretRef("team-1", created.body.id)), null);
});
