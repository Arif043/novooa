import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {knowledgeNotes, teams} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {knowledgeNoteRoutes} from "./local-knowledge-note-routes.js";
import {knowledgeNotesWithLinks} from "./sqlite-knowledge-link-projection.js";
import {SQLiteKnowledgeBaseStore} from "./sqlite-knowledge-base-store.js";

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Andere", owner_uid: "u"});
  await database.insert(knowledgeNotes).values([
    {id: "source", team_id: "team-1", title: "Index", content: "[[Ziel]] [[target]]"},
    {id: "target", team_id: "team-1", title: "Ziel", path: "ziel.md"},
    {id: "other-base", team_id: "team-1", knowledge_base_id: "other", title: "Ziel"},
    {id: "foreign", team_id: "team-2", title: "Ziel"},
  ]);
  const routes = testingRoutes(knowledgeNoteRoutes, {database, notifier: {publish: () => undefined}});
  return {database, routes, store: new SQLiteKnowledgeBaseStore(database)};
}

const attachment = {knowledgeBaseId: "default", noteId: "source", title: "Index", path: "index.md"};

test("API and workflow store derive the same links within team and knowledge base", async (t) => {
  const {database, routes, store} = await fixture(t);
  const listed = (await routes.handle({url: "/v1/knowledge-notes", body: {}}))?.body as {
    items: Array<{id: string; outgoingLinks: string[]}>;
  };
  assert.deepEqual(listed.items.find((note) => note.id === "source")?.outgoingLinks, ["target"]);
  assert.deepEqual((await store.loadNote("team-1", attachment)).outgoingLinks, ["target"]);
  await assert.rejects(store.loadNote("team-2", attachment), /Wissensnotiz fehlt/);
  await assert.rejects(store.loadNote("team-1", {...attachment, knowledgeBaseId: "other"}), /Wissensnotiz fehlt/);
  assert.ok(!(await database.all<{name: string}>(sql`PRAGMA table_info(knowledge_notes)`))
    .some((column) => column.name === "outgoing_links_json"));
});

test("creating, renaming and deleting targets updates links without rewriting their source", async (t) => {
  const {database, routes, store} = await fixture(t);
  await database.update(knowledgeNotes).set({content: "[[Neu]]"}).where(eq(knowledgeNotes.id, "source"));
  assert.deepEqual((await store.loadNote("team-1", attachment)).outgoingLinks, []);
  const renamed = await routes.handle({method: "PUT", url: "/v1/knowledge-notes/target", body: {title: "Neu", path: "neu.md"}});
  assert.equal(renamed?.statusCode, 200);
  assert.deepEqual((await store.loadNote("team-1", attachment)).outgoingLinks, ["target"]);
  await routes.handle({method: "DELETE", url: "/v1/knowledge-notes/target", body: {}});
  assert.deepEqual((await store.loadNote("team-1", attachment)).outgoingLinks, []);
  const created = await routes.handle({method: "POST", url: "/v1/knowledge-notes", body: {title: "Neu", path: "neu.md"}});
  assert.equal(created?.statusCode, 201);
  assert.deepEqual((await store.loadNote("team-1", attachment)).outgoingLinks, [(created?.body as {id: string}).id]);
  assert.equal((await database.select().from(knowledgeNotes).where(eq(knowledgeNotes.id, "source")).get())?.content, "[[Neu]]");
});

test("client projections cannot override Markdown and content updates immediately replace links", async (t) => {
  const {routes, store} = await fixture(t);
  const updated = await routes.handle({method: "PUT", url: "/v1/knowledge-notes/source",
    body: {title: "Index", content: "[Lesen](ziel.md)", outgoingLinks: ["foreign", "other-base"]}});
  assert.deepEqual((updated?.body as {outgoingLinks: string[]}).outgoingLinks, ["target"]);
  await routes.handle({method: "PUT", url: "/v1/knowledge-notes/source", body: {title: "Index", content: "Ohne Link"}});
  assert.deepEqual((await store.loadNote("team-1", attachment)).outgoingLinks, []);
});

test("graph reads react to direct SQL path changes and resolve ID links after a rename", async (t) => {
  const {database, store} = await fixture(t);
  await database.update(knowledgeNotes).set({title: "Anders", path: "anders.md"}).where(eq(knowledgeNotes.id, "target"));
  assert.deepEqual((await store.loadNote("team-1", attachment)).outgoingLinks, ["target"]);
  await database.update(knowledgeNotes).set({content: "[Lesen](ziel.md)"}).where(eq(knowledgeNotes.id, "source"));
  assert.deepEqual((await knowledgeNotesWithLinks(database, "team-1")).find((note) => note.id === "source")?.outgoingLinks, []);
  await database.update(knowledgeNotes).set({content: "[Lesen](anders.md)"}).where(eq(knowledgeNotes.id, "source"));
  assert.deepEqual((await store.loadNote("team-1", attachment)).outgoingLinks, ["target"]);
});
