import assert from "node:assert/strict";
import {createHmac} from "node:crypto";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {tasks} from "../../../../db/schema.js";
import {createLocalRuntimeHttpServer} from "../../../../shared/local/local-runtime-http-server.js";
import {testingRoutes, testWorkspace} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {cycleGuardFor} from "../../../scheduling/domain/usecases/trigger-cycle-guard-test-support.js";
import {taskTriggerRoutes} from "../../../scheduling/infrastructure/local/local-task-trigger-routes.js";
import {SQLiteTaskTriggerStore} from "../../../scheduling/infrastructure/local/sqlite-task-trigger-store.js";
import {webhookSecretsFor} from "../../../scheduling/infrastructure/local/webhook-secrets-test-support.js";
import {TokenBucketRateLimiter} from "../../../skills/domain/usecases/token-bucket-rate-limiter.js";
import {ReceiveWebhook} from "../../domain/usecases/receive-webhook.js";
import {InMemoryBucketStateStore} from "./in-memory-bucket-state-store.js";
import {webhookRoutes} from "./local-webhook-routes.js";

type Created = {id: string; eventConfig: {webhook: {token: string}}};

/** Der echte Weg: Auslöser per API anlegen, dann über den vollständigen Server aufrufen. */
async function flow(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(tasks).values({id: "a", team_id: "team-1", title: "A", graph_json: "{}", created_by_uid: "u"});
  const secrets = webhookSecretsFor(database);
  const api = testingRoutes(taskTriggerRoutes, {
    database, notifier: new LocalRuntimeRealtimeNotifier(), cycleGuard: cycleGuardFor(database), webhookSecrets: secrets,
  });
  const created = await api.handle({method: "POST", url: "/v1/task-triggers", body: {
    taskId: "a", type: "event", eventConfig: {source: "webhookReceived", webhook: {
      validationParameter: "validationToken",
      verification: {kind: "hmac", header: "X-Hub-Signature-256", algorithm: "sha256", encoding: "hex", prefix: "sha256="},
      secret: "geheim",
    }},
  }});
  const trigger = created?.body as Created;
  const runs: Array<{input: {event: {body: unknown}}}> = [];
  const limiter = new TokenBucketRateLimiter(new InMemoryBucketStateStore(), {current: async () => ({capacity: 100, refillPerSecond: 10})});
  const webhooks = new ReceiveWebhook({
    teamId: "team-1", triggerStore: new SQLiteTaskTriggerStore(database), secrets,
    taskStore: {loadTask: async () => ({id: "a"})} as never,
    taskRunStore: {enqueueTaskRun: async (run: never) => {runs.push(run); return {runId: "run-1"};}} as never,
    taskRunDispatcher: {dispatchTaskRun: async () => undefined},
    failures: limiter, triggers: limiter,
  });
  const server = createLocalRuntimeHttpServer(async (routes) => {
    await routes.register(webhookRoutes, {
      licenses: {activeContext: () => ({}) as never, status: () => ({state: "active"}) as never},
      workspaceContext: () => testWorkspace({webhooks}),
    });
  });
  t.after(() => server.close());
  return {server, api, trigger, runs, url: `/hooks/${trigger.id}/${trigger.eventConfig.webhook.token}`};
}

test("ein angelegter Auslöser ist über den vollständigen Server erreichbar und prüft die Signatur", async (t) => {
  const {server, runs, url} = await flow(t);
  const body = '{"bestellung": 42}';
  const signature = `sha256=${createHmac("sha256", "geheim").update(body).digest("hex")}`;

  const accepted = await server.inject({method: "POST", url, payload: body, headers: {"content-type": "application/json", "x-hub-signature-256": signature}});
  assert.equal(accepted.statusCode, 202);
  assert.deepEqual(runs[0]?.input.event.body, {bestellung: 42});

  const forged = await server.inject({method: "POST", url, payload: body, headers: {"content-type": "application/json", "x-hub-signature-256": "sha256=00"}});
  assert.equal(forged.statusCode, 401);
  assert.equal(runs.length, 1);
});

test("Einrichtungsprüfung, falsches Token und Token-Erneuerung über den vollständigen Server", async (t) => {
  const {server, api, trigger, url} = await flow(t);
  const echo = await server.inject({method: "POST", url: `${url}?validationToken=hallo`});
  assert.equal(echo.statusCode, 200);
  assert.equal(echo.body, "hallo");

  const wrong = await server.inject({method: "POST", url: `/hooks/${trigger.id}/falsch`});
  assert.equal(wrong.statusCode, 404);
  assert.equal(wrong.body, (await server.inject({method: "POST", url: "/hooks/unbekannt/falsch"})).body);

  const rotated = await api.handle({method: "POST", url: `/v1/task-triggers/${trigger.id}/webhook-token`, body: {}});
  const next = (rotated?.body as Created).eventConfig.webhook.token;
  assert.equal((await server.inject({method: "POST", url})).statusCode, 404);
  assert.equal((await server.inject({method: "POST", url: `/hooks/${trigger.id}/${next}?validationToken=neu`})).body, "neu");
});
