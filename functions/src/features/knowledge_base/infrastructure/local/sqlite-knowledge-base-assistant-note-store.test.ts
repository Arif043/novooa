import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {knowledgeNotes} from "../../../../db/schema.js";
import {SQLiteKnowledgeBaseAssistantNoteStore} from "./sqlite-knowledge-base-assistant-note-store.js";

test("lists local assistant notes for the active team", async (t) => {
  const database = await runtimeTestDatabase(t);
  await database.insert(knowledgeNotes).values({id: "note-1", team_id: "team-1", title: "Plan", path: "plan.md", content: "Inhalt"});
  const notes = await new SQLiteKnowledgeBaseAssistantNoteStore(database).listNotes("team-1");
  assert.deepEqual(notes, [{id: "note-1", title: "Plan", path: "plan.md", content: "Inhalt"}]);
  assert.deepEqual(await new SQLiteKnowledgeBaseAssistantNoteStore(database).listNotes("other-team"), []);
});

test("returns no local assistant note when it is absent", async (t) => {
  const database = await runtimeTestDatabase(t);
  assert.equal(await new SQLiteKnowledgeBaseAssistantNoteStore(database).findNote("team-1", "missing"), null);
});
