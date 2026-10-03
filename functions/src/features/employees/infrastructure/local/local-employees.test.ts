import {eq} from "drizzle-orm";
import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {employees, teams} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {createEmployeeRoutesOptions} from "./employees-composition.js";
import {employeeRoutes} from "./local-employee-routes.js";
import {SqliteEmployeeStore} from "./sqlite-employee-store.js";

async function harness(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  const published: string[] = [];
  const options = createEmployeeRoutesOptions(database, {publish: (topic) => published.push(topic)});
  return {database, published, routes: testingRoutes(employeeRoutes, options)};
}

const body = (name: string, constraint = "Sei freundlich.", skills: string[] = []) => ({name, constraint, skills});

test("creates, lists alphabetically, updates and deletes an employee", async (t) => {
  const {routes, published} = await harness(t);

  const created = await routes.handle({method: "POST", url: "/v1/employees", body: body("Zoe", "Zoe-Regeln", ["pdf"])});
  await routes.handle({method: "POST", url: "/v1/employees", body: body("anna")});
  const id = (created?.body as {id: string}).id;
  const listed = await routes.handle({method: "GET", url: "/v1/employees", body: {}});
  const updated = await routes.handle({method: "PUT", url: `/v1/employees/${id}`, body: body("Zoe Neu", "Neue Regeln", ["mails", "pdf"])});
  const removed = await routes.handle({method: "DELETE", url: `/v1/employees/${id}`, body: {}});
  const after = await routes.handle({method: "GET", url: "/v1/employees", body: {}});

  assert.equal(created?.statusCode, 201);
  assert.deepEqual((listed?.body as {items: Array<{name: string}>}).items.map((item) => item.name), ["anna", "Zoe"]);
  assert.deepEqual((created?.body as {skills: string[]; constraint: string}).skills, ["pdf"]);
  assert.equal(updated?.statusCode, 200);
  assert.deepEqual(updated?.body && {name: (updated.body as {name: string}).name, skills: (updated.body as {skills: string[]}).skills},
    {name: "Zoe Neu", skills: ["mails", "pdf"]});
  assert.equal(removed?.statusCode, 200);
  assert.deepEqual((after?.body as {items: Array<{name: string}>}).items.map((item) => item.name), ["anna"]);
  assert.deepEqual(published, ["employees", "employees", "employees", "employees"]);
});

test("rejects invalid input with a readable 400 and duplicate names with 409", async (t) => {
  const {routes, published} = await harness(t);
  await routes.handle({method: "POST", url: "/v1/employees", body: body("Rezeption")});

  const empty = await routes.handle({method: "POST", url: "/v1/employees", body: body("  ")});
  const badSkill = await routes.handle({method: "POST", url: "/v1/employees", body: body("Neu", "", ["../x"])});
  const taken = await routes.handle({method: "POST", url: "/v1/employees", body: body(" rezeption ")});

  assert.equal(empty?.statusCode, 400);
  assert.match((empty?.body as {error: string}).error, /Namen/);
  assert.equal(badSkill?.statusCode, 400);
  assert.equal(taken?.statusCode, 409);
  assert.match((taken?.body as {error: string}).error, /schon einen Mitarbeiter/);
  assert.deepEqual(published, ["employees"], "failed requests publish nothing");
});

test("renaming to the own name is fine, renaming to another employee's name is not", async (t) => {
  const {routes} = await harness(t);
  const first = await routes.handle({method: "POST", url: "/v1/employees", body: body("Eins")});
  const second = await routes.handle({method: "POST", url: "/v1/employees", body: body("Zwei")});
  const firstId = (first?.body as {id: string}).id;
  const secondId = (second?.body as {id: string}).id;

  const own = await routes.handle({method: "PUT", url: `/v1/employees/${firstId}`, body: body("EINS", "geändert")});
  const clash = await routes.handle({method: "PUT", url: `/v1/employees/${secondId}`, body: body("eins")});

  assert.equal(own?.statusCode, 200);
  assert.equal(clash?.statusCode, 409);
});

test("unknown employees answer 404", async (t) => {
  const {routes} = await harness(t);

  const update = await routes.handle({method: "PUT", url: "/v1/employees/gibt-es-nicht", body: body("X")});
  const remove = await routes.handle({method: "DELETE", url: "/v1/employees/gibt-es-nicht", body: {}});

  assert.equal(update?.statusCode, 404);
  assert.equal(remove?.statusCode, 404);
  assert.match((update?.body as {error: string}).error, /nicht gefunden/);
});

test("employees belong to their team and are removed with it", async (t) => {
  const {database} = await harness(t);
  await database.insert(teams).values({id: "team-2", name: "Anderes Team", owner_uid: "user-2"});
  const store = new SqliteEmployeeStore(database);

  const mine = await store.create("team-1", {name: "Eins", constraint: "", skills: []});

  assert.deepEqual(await store.list("team-2"), []);
  assert.equal(await store.find("team-2", mine.id), null, "not visible from another team");
  assert.equal(await store.update("team-2", mine.id, {name: "Fremd", constraint: "", skills: []}), null);
  assert.equal(await store.delete("team-2", mine.id), false);
  assert.equal((await store.find("team-1", mine.id))?.name, "Eins");
});

test("stored skills survive a round trip in order and broken JSON reads as no skills", async (t) => {
  const {database} = await harness(t);
  const store = new SqliteEmployeeStore(database);
  const created = await store.create("team-1", {name: "Eins", constraint: "Regel", skills: ["b", "a"]});

  assert.deepEqual((await store.find("team-1", created.id))?.skills, ["b", "a"]);
  await database.update(employees).set({skills_json: "kaputt"}).where(eq(employees.id, created.id));
  assert.deepEqual((await store.find("team-1", created.id))?.skills, []);
});

test("created and updated timestamps are set and updatedAt moves on change", async (t) => {
  const {database} = await harness(t);
  let now = new Date("2026-01-01T10:00:00.000Z");
  const store = new SqliteEmployeeStore(database, () => now);

  const created = await store.create("team-1", {name: "Eins", constraint: "", skills: []});
  now = new Date("2026-01-02T10:00:00.000Z");
  const updated = await store.update("team-1", created.id, {name: "Eins", constraint: "neu", skills: []});

  assert.equal(created.createdAt, "2026-01-01T10:00:00.000Z");
  assert.equal(updated?.createdAt, "2026-01-01T10:00:00.000Z");
  assert.equal(updated?.updatedAt, "2026-01-02T10:00:00.000Z");
});
