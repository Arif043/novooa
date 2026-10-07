import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {languageModelSecrets, tasks, taskRuns, taskTriggers, teams} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {SQLiteTaskDefinitionStore} from "../../../task_execution/infrastructure/local/sqlite-task-definition-store.js";
import {taskDefinitionRoutes} from "../../../task_execution/infrastructure/local/local-task-definition-routes.js";
import {cycleGuardFor} from "../../domain/usecases/trigger-cycle-guard-test-support.js";
import {webhookSecretRef} from "../../domain/repositories/webhook-secret-store.js";
import {taskTriggerRoutes} from "./local-task-trigger-routes.js";
import {SQLiteTaskTriggerStore} from "./sqlite-task-trigger-store.js";
import {webhookSecretsFor} from "./webhook-secrets-test-support.js";

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Zweites Team", owner_uid: "u"});
  await database.insert(tasks).values([1, 2].map((id) => ({id: `task-${id}`, team_id: `team-${id}`,
    title: `Aufgabe ${id}`, graph_json: "{}", created_by_uid: "u"})));
  await database.insert(taskTriggers).values([
    {id: "schedule-1", task_id: "task-1", type: "schedule", config_json: '{"kind":"daily","timezone":"UTC","timeOfDay":"09:00"}',
      next_run_at: "2026-01-01T09:00:00.000Z", created_by_uid: "u"},
    {id: "event-2", task_id: "task-2", type: "event", event_config_json: '{"source":"webhookReceived","webhook":{"token":"original"}}', created_by_uid: "u"},
  ]);
  const secrets = webhookSecretsFor(database);
  await secrets.write(webhookSecretRef("team-1", "schedule-1"), "eins");
  await secrets.write(webhookSecretRef("team-2", "event-2"), "zwei");
  return {database, secrets, store: new SQLiteTaskTriggerStore(database)};
}

test("schedule and event queries derive the team and current title from the task", async (t) => {
  const {database, store} = await fixture(t);
  const due = await store.listDueScheduleTriggers(new Date("2026-01-02"), 10);
  assert.deepEqual(due.map(({id, teamId, taskId}) => ({id, teamId, taskId})),
    [{id: "schedule-1", teamId: "team-1", taskId: "task-1"}]);
  assert.deepEqual(await store.listEnabledEventTriggers("team-1"), []);
  assert.equal((await store.listEnabledEventTriggers("team-2"))[0].id, "event-2");
  const columns = await database.all<{name: string}>(sql`PRAGMA table_info(task_triggers)`);
  assert.ok(!columns.some((column) => column.name === "team_id"));
  await assert.rejects(database.insert(taskTriggers).values({id: "orphan", task_id: "missing", type: "event", created_by_uid: "u"}));
});

test("worker updates cannot change another team's trigger", async (t) => {
  const {database, store} = await fixture(t);
  const [schedule] = await store.listDueScheduleTriggers(new Date("2026-01-02"), 10);
  await store.advanceScheduleTrigger({...schedule, teamId: "team-2"}, null);
  await store.markScheduleTriggerRan({...schedule, teamId: "team-2"}, new Date(), null, "foreign-run");
  const [event] = await store.listEnabledEventTriggers("team-2");
  await store.markEventTriggerRan({...event, teamId: "team-1"}, "foreign-run");
  const rows = await database.select().from(taskTriggers);
  assert.ok(rows.every((row) => row.enabled === 1 && row.last_run_id === null));
  await store.advanceScheduleTrigger(schedule, null);
  assert.equal((await database.select().from(taskTriggers).where(eq(taskTriggers.id, schedule.id)))[0].enabled, 0);
});

test("HTTP lists and mutations preserve team boundaries after normalization", async (t) => {
  const {database, secrets} = await fixture(t);
  await database.update(tasks).set({title: "Aktueller Titel"}).where(eq(tasks.id, "task-1"));
  const routes = testingRoutes(taskTriggerRoutes, {database, webhookSecrets: secrets,
    notifier: {publish: () => undefined}, cycleGuard: cycleGuardFor(database)});
  const listed = await routes.handle({method: "GET", url: "/v1/task-triggers", body: {}});
  assert.deepEqual((listed?.body as {items: {id: string; teamId: string; taskTitle: string}[]}).items
    .map(({id, teamId, taskTitle}) => ({id, teamId, taskTitle})),
  [{id: "schedule-1", teamId: "team-1", taskTitle: "Aktueller Titel"}]);
  assert.equal((await routes.handle({method: "PUT", url: "/v1/task-triggers/event-2/enabled", body: {enabled: false}}))?.statusCode, 404);
  assert.equal((await routes.handle({method: "POST", url: "/v1/task-triggers/event-2/webhook-token", body: {}}))?.statusCode, 404);
  await routes.handle({method: "DELETE", url: "/v1/task-triggers/event-2", body: {}});
  assert.equal((await database.select().from(taskTriggers).where(eq(taskTriggers.id, "event-2")))[0].enabled, 1);
  assert.equal(await secrets.read(webhookSecretRef("team-2", "event-2")), "zwei");
  assert.equal((await routes.handle({method: "POST", url: "/v1/task-triggers", body:
    {taskId: "task-2", type: "event", eventConfig: {source: "webhookReceived"}}}))?.statusCode, 400);
});

test("deleting a task removes its triggers and secrets while preserving historical runs", async (t) => {
  const {database, secrets} = await fixture(t);
  await database.insert(taskRuns).values({id: "run-1", team_id: "team-1", task_id: "task-1", task_title: "Alter Titel", status: "completed"});
  const definitions = new SQLiteTaskDefinitionStore(database);
  await definitions.delete("team-2", "task-1");
  assert.equal(await secrets.read(webhookSecretRef("team-1", "schedule-1")), "eins");
  await definitions.delete("team-1", "task-1");
  assert.equal(await secrets.read(webhookSecretRef("team-1", "schedule-1")), null);
  assert.equal(await secrets.read(webhookSecretRef("team-2", "event-2")), "zwei");
  assert.deepEqual((await database.select().from(taskTriggers)).map((row) => row.id), ["event-2"]);
  assert.equal((await database.select().from(taskRuns))[0].task_title, "Alter Titel");
});

test("a failed task deletion rolls back trigger secret cleanup", async (t) => {
  const {database, secrets} = await fixture(t);
  await database.run(sql`CREATE TRIGGER reject_task_deletion BEFORE DELETE ON tasks
    BEGIN SELECT RAISE(ABORT, 'Löschen fehlgeschlagen'); END`);
  await assert.rejects(new SQLiteTaskDefinitionStore(database).delete("team-1", "task-1"));
  assert.equal(await secrets.read(webhookSecretRef("team-1", "schedule-1")), "eins");
  assert.equal((await database.select().from(taskTriggers)).length, 2);
  assert.equal((await database.select().from(languageModelSecrets)).length, 2);
});

test("task deletion publishes both affected resource topics", async (t) => {
  const {database} = await fixture(t);
  const topics: string[] = [];
  const routes = testingRoutes(taskDefinitionRoutes, {store: new SQLiteTaskDefinitionStore(database),
    cycleGuard: cycleGuardFor(database), notifier: {publish: (topic) => {topics.push(topic);}}});
  assert.equal((await routes.handle({method: "DELETE", url: "/v1/tasks/task-1", body: {}}))?.statusCode, 204);
  assert.deepEqual(topics, ["tasks", "task-triggers"]);
});
