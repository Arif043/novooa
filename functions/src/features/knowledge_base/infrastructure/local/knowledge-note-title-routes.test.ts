import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {knowledgeNotes} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {knowledgeNoteRoutes} from "./local-knowledge-note-routes.js";

async function routesWith(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(knowledgeNotes).values([
    {id: "fristen", team_id: "team-1", title: "Fristen"},
    {id: "mahnung", team_id: "team-1", title: "Mahnung"},
    {id: "andere-basis", team_id: "team-1", knowledge_base_id: "other", title: "Übergabe"},
  ]);
  return testingRoutes(knowledgeNoteRoutes, {database, notifier: {publish: () => undefined}});
}

test("rejects a new note whose title already exists, regardless of case", async (t) => {
  const routes = await routesWith(t);

  const response = await routes.handle({method: "POST", url: "/v1/knowledge-notes", body: {title: " fristen "}});

  assert.equal(response?.statusCode, 409);
  assert.deepEqual(response?.body, {error: "Eine Notiz mit dem Titel „fristen“ gibt es schon.", code: "duplicate_title"});
});

test("rejects renaming a note to the title of another note", async (t) => {
  const routes = await routesWith(t);

  const response = await routes.handle({method: "PUT", url: "/v1/knowledge-notes/mahnung", body: {title: "FRISTEN"}});

  assert.equal(response?.statusCode, 409);
});

test("saves a note under its own title and allows the same title in another knowledge base", async (t) => {
  const routes = await routesWith(t);

  const own = await routes.handle({method: "PUT", url: "/v1/knowledge-notes/fristen", body: {title: "fristen", content: "Neu"}});
  const otherBase = await routes.handle({method: "POST", url: "/v1/knowledge-notes", body: {title: "Übergabe"}});

  assert.equal(own?.statusCode, 200);
  assert.equal(otherBase?.statusCode, 201);
});

test("compares umlauts regardless of case", async (t) => {
  const routes = await routesWith(t);
  await routes.handle({method: "POST", url: "/v1/knowledge-notes", body: {title: "Übergabe"}});

  const response = await routes.handle({method: "POST", url: "/v1/knowledge-notes", body: {title: "übergabe"}});

  assert.equal(response?.statusCode, 409);
});
