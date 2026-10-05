import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {fileFolders} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {taskDefinitionRoutes} from "../../../task_execution/infrastructure/local/local-task-definition-routes.js";
import {SQLiteTaskDefinitionStore} from "../../../task_execution/infrastructure/local/sqlite-task-definition-store.js";
import {cycleGuardFor} from "../../domain/usecases/trigger-cycle-guard-test-support.js";
import {webhookSecretsFor} from "./webhook-secrets-test-support.js";
import {taskTriggerRoutes} from "./local-task-trigger-routes.js";

type Body = {error?: string; warnings?: string[]; blocked?: string | null; id?: string};

async function setup(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(fileFolders).values([
    {id: "eingang", team_id: "team-1", owner_uid: "u", name: "Eingang"},
    {id: "ausgang", team_id: "team-1", owner_uid: "u", name: "Ausgang"},
  ]);
  const guard = cycleGuardFor(database);
  const notifier = new LocalRuntimeRealtimeNotifier();
  const tasks = testingRoutes(taskDefinitionRoutes, {store: new SQLiteTaskDefinitionStore(database), notifier, cycleGuard: guard, webhookSecrets: webhookSecretsFor(database)});
  const triggers = testingRoutes(taskTriggerRoutes, {database, notifier, cycleGuard: guard, webhookSecrets: webhookSecretsFor(database)});
  return {tasks, triggers};
}

function taskBody(id: string, writesTo: string | null) {
  const nodes = writesTo === null ? [] : [{
    id: "w", primitive: "writeFile", title: "Schreiben", description: "", outputName: "datei",
    config: {primitive: "writeFile", fileName: "bericht.txt", contentType: "text/plain", contentTemplate: "x", folderId: writesTo},
  }];
  return {id, title: `Aufgabe ${id}`, objective: "", selectedNodeId: "", graph: {nodes, edges: []}};
}

function watchBody(taskId: string, folderId: string, enabled = true) {
  return {
    taskId, type: "event", enabled, policy: {ifRunning: "skipIfRunning"},
    eventConfig: {source: "fileCreated", target: {kind: "folder", id: folderId, label: folderId, includeSubfolders: true}},
  };
}

async function body<T = Body>(response: Promise<{body: object; statusCode: number} | null>) {
  const result = await response;
  assert.ok(result);
  return {status: result.statusCode, body: result.body as T};
}

test("ein Trigger, der seine eigene Aufgabe über deren Ausgabeverzeichnis startet, wird abgelehnt", async (t) => {
  const {tasks, triggers} = await setup(t);
  await tasks.handle({method: "PUT", url: "/v1/tasks/a", body: taskBody("a", "eingang")});

  const response = await body(triggers.handle({method: "POST", url: "/v1/task-triggers", body: watchBody("a", "eingang")}));
  const listed = await body<{items: unknown[]}>(triggers.handle({method: "GET", url: "/v1/task-triggers", body: {}}));

  assert.equal(response.status, 400);
  assert.match(response.body.error ?? "", /immer wieder selbst starten/);
  assert.equal(listed.body.items.length, 0);
});

test("ein Trigger auf ein anderes Verzeichnis ist zulässig", async (t) => {
  const {tasks, triggers} = await setup(t);
  await tasks.handle({method: "PUT", url: "/v1/tasks/a", body: taskBody("a", "eingang")});

  const response = await body(triggers.handle({method: "POST", url: "/v1/task-triggers", body: watchBody("a", "ausgang")}));

  assert.equal(response.status, 201);
});

test("die Vorabprüfung meldet eine mögliche Schleife über zwei Aufgaben als Warnung", async (t) => {
  const {tasks, triggers} = await setup(t);
  await tasks.handle({method: "PUT", url: "/v1/tasks/a", body: taskBody("a", "ausgang")});
  await tasks.handle({method: "PUT", url: "/v1/tasks/b", body: taskBody("b", "eingang")});
  await triggers.handle({method: "POST", url: "/v1/task-triggers", body: watchBody("a", "eingang")});

  const analysis = await body(triggers.handle({method: "POST", url: "/v1/task-triggers/analysis", body: watchBody("b", "ausgang")}));
  const created = await body(triggers.handle({method: "POST", url: "/v1/task-triggers", body: watchBody("b", "ausgang")}));

  assert.equal(analysis.status, 200);
  assert.equal(analysis.body.blocked, null);
  assert.equal(analysis.body.warnings?.length, 1);
  assert.match(analysis.body.warnings?.[0] ?? "", /Mögliche Schleife: „Aufgabe a“ → „Aufgabe b“ → „Aufgabe a“/);
  assert.equal(created.status, 201, "eine Warnung verhindert das Anlegen nicht");
});

test("die Vorabprüfung nennt eine Selbstschleife als blockierend", async (t) => {
  const {tasks, triggers} = await setup(t);
  await tasks.handle({method: "PUT", url: "/v1/tasks/a", body: taskBody("a", "eingang")});

  const analysis = await body(triggers.handle({method: "POST", url: "/v1/task-triggers/analysis", body: watchBody("a", "eingang")}));

  assert.match(analysis.body.blocked ?? "", /Aufgabe a/);
});

test("Speichern einer Aufgabe, die sich über einen bestehenden Trigger selbst startet, wird abgelehnt", async (t) => {
  const {tasks, triggers} = await setup(t);
  await tasks.handle({method: "PUT", url: "/v1/tasks/a", body: taskBody("a", null)});
  await triggers.handle({method: "POST", url: "/v1/task-triggers", body: watchBody("a", "eingang")});

  const rejected = await body(tasks.handle({method: "PUT", url: "/v1/tasks/a", body: taskBody("a", "eingang")}));
  const accepted = await body(tasks.handle({method: "PUT", url: "/v1/tasks/a", body: taskBody("a", "ausgang")}));

  assert.equal(rejected.status, 400);
  assert.match(rejected.body.error ?? "", /immer wieder selbst starten/);
  assert.equal(accepted.status, 200);
  assert.equal(accepted.body.warnings, undefined);
});

test("Speichern einer Aufgabe, die einen Zyklus schließt, liefert eine Warnung", async (t) => {
  const {tasks, triggers} = await setup(t);
  await tasks.handle({method: "PUT", url: "/v1/tasks/a", body: taskBody("a", "ausgang")});
  await tasks.handle({method: "PUT", url: "/v1/tasks/b", body: taskBody("b", null)});
  await triggers.handle({method: "POST", url: "/v1/task-triggers", body: watchBody("a", "eingang")});
  await triggers.handle({method: "POST", url: "/v1/task-triggers", body: watchBody("b", "ausgang")});

  const saved = await body(tasks.handle({method: "PUT", url: "/v1/tasks/b", body: taskBody("b", "eingang")}));

  assert.equal(saved.status, 200);
  assert.equal(saved.body.warnings?.length, 1);
});

test("ein pausierter Selbstschleifen-Trigger lässt sich nicht aktivieren", async (t) => {
  const {tasks, triggers} = await setup(t);
  await tasks.handle({method: "PUT", url: "/v1/tasks/a", body: taskBody("a", "eingang")});
  const created = await body(triggers.handle({
    method: "POST", url: "/v1/task-triggers", body: watchBody("a", "eingang", false),
  }));

  const enabled = await body(triggers.handle({
    method: "PUT", url: `/v1/task-triggers/${created.body.id}/enabled`, body: {enabled: true},
  }));

  assert.equal(created.status, 201, "ein pausierter Trigger schleift nicht");
  assert.equal(enabled.status, 400);
});
