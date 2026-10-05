import assert from "node:assert/strict";
import {createHmac} from "node:crypto";
import test from "node:test";
import {eventTriggerConfigFrom} from "../../../scheduling/domain/entities/event-trigger-config.js";
import {type EventTaskTrigger} from "../../../scheduling/domain/repositories/task-trigger-store.js";
import {TokenBucketRateLimiter} from "../../../skills/domain/usecases/token-bucket-rate-limiter.js";
import {InMemoryBucketStateStore} from "../../infrastructure/local/in-memory-bucket-state-store.js";
import {type WebhookRequest} from "../entities/webhook-event.js";
import {ReceiveWebhook} from "./receive-webhook.js";

const token = "t".repeat(43);
const hmac = {kind: "hmac", header: "x-signature", algorithm: "sha256", encoding: "hex", prefix: "sha256="};

function triggerWith(webhook: Record<string, unknown> = {}, enabled = true): EventTaskTrigger & {enabled: boolean} {
  return {
    id: "trigger-1", teamId: "team-1", taskId: "task-1", type: "event", enabled,
    eventConfig: eventTriggerConfigFrom({source: "webhookReceived", webhook: {token, ...webhook}}),
  };
}

function setup(options: {trigger?: EventTaskTrigger & {enabled: boolean}; secret?: string | null; failures?: number; perTrigger?: number} = {}) {
  const trigger = options.trigger ?? triggerWith();
  const runs: Array<{input: Record<string, unknown>; context: string}> = [];
  const ran: string[] = [];
  const buckets = new InMemoryBucketStateStore();
  const limiter = (capacity: number) => new TokenBucketRateLimiter(buckets, {current: async () => ({capacity, refillPerSecond: 0.001})});
  const receiver = new ReceiveWebhook({
    teamId: "team-1",
    triggerStore: {
      listEnabledEventTriggers: async () => trigger.enabled ? [trigger] : [],
      markEventTriggerRan: async (_trigger: unknown, runId: string) => {ran.push(runId);},
    } as never,
    taskStore: {loadTask: async () => ({id: "task-1"})} as never,
    taskRunStore: {enqueueTaskRun: async (run: {input: Record<string, unknown>; context: string}) => {runs.push(run); return {runId: `run-${runs.length}`};}} as never,
    taskRunDispatcher: {dispatchTaskRun: async () => undefined},
    secrets: {read: async () => options.secret === undefined ? "geheim" : options.secret},
    failures: limiter(options.failures ?? 100),
    triggers: limiter(options.perTrigger ?? 100),
    now: () => new Date("2026-10-05T10:00:00Z"),
  });
  return {receiver, runs, ran};
}

function request(overrides: Partial<WebhookRequest> = {}, body = "{}"): WebhookRequest {
  return {
    triggerId: "trigger-1", token, method: "POST", query: {},
    headers: {"content-type": "application/json"}, rawBody: Buffer.from(body), ...overrides,
  };
}

function sign(body: string | Buffer, secret = "geheim", algorithm = "sha256") {
  return createHmac(algorithm, secret).update(body);
}

test("ein gültiger Aufruf startet einen Lauf mit dem Ereignis", async () => {
  const {receiver, runs, ran} = setup();
  const result = await receiver.receive(request({query: {a: "1"}}, '{"bestellung": 7}'));
  assert.deepEqual(result, {kind: "accepted"});
  assert.equal(runs.length, 1);
  assert.deepEqual(runs[0]?.input.event, {
    type: "webhookReceived", method: "POST", query: {a: "1"}, headers: {"content-type": "application/json"},
    body: {bestellung: 7}, receivedAt: "2026-10-05T10:00:00.000Z",
  });
  assert.match(runs[0]?.context ?? "", /Webhook empfangen/);
  assert.equal(ran.length, 1);
});

test("der Kontexttext enthält weder Token noch Inhalt", async () => {
  const {receiver, runs} = setup();
  await receiver.receive(request({}, '{"geheim": "inhalt"}'));
  assert.equal((runs[0]?.context ?? "").includes(token), false);
  assert.equal((runs[0]?.context ?? "").includes("inhalt"), false);
});

test("falsches Token, unbekannte Kennung und deaktivierter Auslöser sehen gleich aus und starten nichts", async () => {
  for (const [name, setupOptions, overrides] of [
    ["falsches Token", {}, {token: "x".repeat(43)}],
    ["kürzeres Token", {}, {token: "x"}],
    ["unbekannte Kennung", {}, {triggerId: "anders"}],
    ["deaktiviert", {trigger: triggerWith({}, false)}, {}],
  ] as const) {
    const {receiver, runs} = setup(setupOptions);
    assert.deepEqual(await receiver.receive(request(overrides)), {kind: "notFound"}, name);
    assert.equal(runs.length, 0, name);
  }
});

test("ein Auslöser ohne vergebenes Token ist nicht erreichbar", async () => {
  const {receiver} = setup({trigger: triggerWith({token: ""})});
  assert.deepEqual(await receiver.receive(request({token: ""})), {kind: "notFound"});
});

test("viele Fehlversuche werden gebremst, gültige Aufrufe bleiben möglich", async () => {
  const {receiver} = setup({failures: 2});
  const wrong = request({token: "x".repeat(43)});
  assert.equal((await receiver.receive(wrong)).kind, "notFound");
  assert.equal((await receiver.receive(wrong)).kind, "notFound");
  const limited = await receiver.receive(wrong);
  assert.equal(limited.kind, "rateLimited");
  assert.equal((await receiver.receive(request())).kind, "accepted");
});

test("zu viele gültige Aufrufe desselben Auslösers werden gebremst", async () => {
  const {receiver, runs} = setup({perTrigger: 2});
  assert.equal((await receiver.receive(request())).kind, "accepted");
  assert.equal((await receiver.receive(request())).kind, "accepted");
  const limited = await receiver.receive(request());
  assert.equal(limited.kind, "rateLimited");
  assert.equal(runs.length, 2);
});

test("die Einrichtungsprüfung gibt den Parameter zurück und startet keinen Lauf", async () => {
  const {receiver, runs} = setup({trigger: triggerWith({validationParameter: "validationToken"})});
  const result = await receiver.receive(request({query: {validationToken: "abc 123"}}, ""));
  assert.deepEqual(result, {kind: "echo", value: "abc 123"});
  assert.equal(runs.length, 0);
});

test("die Einrichtungsprüfung verlangt dennoch das Token und lehnt Überlanges ab", async () => {
  const {receiver} = setup({trigger: triggerWith({validationParameter: "validationToken"})});
  assert.equal((await receiver.receive(request({token: "x".repeat(43), query: {validationToken: "a"}}))).kind, "notFound");
  assert.equal((await receiver.receive(request({query: {validationToken: "a".repeat(2049)}}))).kind, "badRequest");
});

test("ohne konfigurierten Parameter wird nichts zurückgegeben", async () => {
  const {receiver, runs} = setup();
  assert.equal((await receiver.receive(request({query: {validationToken: "abc"}}))).kind, "accepted");
  assert.equal(runs.length, 1);
});

test("GET ohne Einrichtungsprüfung ist nicht vorhanden", async () => {
  const {receiver, runs} = setup();
  assert.deepEqual(await receiver.receive(request({method: "GET"}, "")), {kind: "notFound"});
  assert.equal(runs.length, 0);
});

test("eine gültige Signatur wird akzeptiert, die Signatur-Kopfzeile bleibt aus dem Ereignis", async () => {
  const body = '{"a":  1}';
  const {receiver, runs} = setup({trigger: triggerWith({verification: hmac})});
  const headers = {"content-type": "application/json", "x-signature": `sha256=${sign(body).digest("hex")}`, "x-andere": "ja"};
  assert.equal((await receiver.receive(request({headers}, body))).kind, "accepted");
  const event = runs[0]?.input.event as {headers: Record<string, string>};
  assert.deepEqual(Object.keys(event.headers).sort(), ["content-type", "x-andere"]);
});

test("die Signatur gilt den Rohbytes, nicht dem geparsten JSON", async () => {
  const signed = '{"a":1}';
  const {receiver, runs} = setup({trigger: triggerWith({verification: hmac})});
  const headers = {"content-type": "application/json", "x-signature": `sha256=${sign(signed).digest("hex")}`};
  assert.equal((await receiver.receive(request({headers}, '{"a": 1}'))).kind, "unauthorized");
  assert.equal(runs.length, 0);
});

test("Signaturen mit falschem Geheimnis, falscher Form oder ohne Kopfzeile werden abgelehnt", async () => {
  const body = "{}";
  const {receiver, runs} = setup({trigger: triggerWith({verification: hmac})});
  const bad = (value: string | undefined) =>
    receiver.receive(request({headers: value === undefined ? {} : {"x-signature": value}}, body));
  assert.equal((await bad(`sha256=${sign(body, "anderes").digest("hex")}`)).kind, "unauthorized");
  assert.equal((await bad(sign(body).digest("hex"))).kind, "unauthorized");
  assert.equal((await bad("sha256=zz")).kind, "unauthorized");
  assert.equal((await bad("sha256=")).kind, "unauthorized");
  assert.equal((await bad("sha256=abcd")).kind, "unauthorized");
  assert.equal((await bad(undefined)).kind, "unauthorized");
  assert.equal(runs.length, 0);
});

test("base64 und sha512 werden unterstützt", async () => {
  const body = "x";
  const verification = {kind: "hmac", header: "x-signature", algorithm: "sha512", encoding: "base64", prefix: ""};
  const {receiver} = setup({trigger: triggerWith({verification})});
  const headers = {"x-signature": sign(body, "geheim", "sha512").digest("base64")};
  assert.equal((await receiver.receive(request({headers}, body))).kind, "accepted");
});

test("fehlt das Geheimnis, wird abgelehnt statt ungeprüft angenommen", async () => {
  const {receiver, runs} = setup({trigger: triggerWith({verification: hmac}), secret: null});
  const headers = {"x-signature": `sha256=${sign("{}").digest("hex")}`};
  assert.equal((await receiver.receive(request({headers}))).kind, "unauthorized");
  assert.equal(runs.length, 0);
});

test("Zugangsdaten-Kopfzeilen gelangen nicht ins Ereignis", async () => {
  const {receiver, runs} = setup();
  const headers = {authorization: "Bearer x", cookie: "s=1", "proxy-authorization": "y", "x-ok": "1"};
  await receiver.receive(request({headers}));
  assert.deepEqual((runs[0]?.input.event as {headers: object}).headers, {"x-ok": "1"});
});

test("Inhalte: Formular als Objekt, anderes und ungültiges JSON als Text", async () => {
  const {receiver, runs} = setup();
  await receiver.receive(request({headers: {"content-type": "application/x-www-form-urlencoded"}}, "a=1&b=zwei+drei"));
  await receiver.receive(request({headers: {"content-type": "text/plain"}}, "Hallo"));
  await receiver.receive(request({headers: {"content-type": "application/json"}}, "{kaputt"));
  const bodies = runs.map((run) => (run.input.event as {body: unknown}).body);
  assert.deepEqual(bodies, [{a: "1", b: "zwei drei"}, "Hallo", "{kaputt"]);
});
