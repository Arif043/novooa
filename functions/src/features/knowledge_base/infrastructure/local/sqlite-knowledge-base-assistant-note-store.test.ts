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

test("lists every note of the team, not only the first fifty", async (t) => {
  const database = await runtimeTestDatabase(t);
  const rows = Array.from({length: 60}, (_, index) => {
    const number = String(index + 1).padStart(2, "0");
    return {id: `note-${number}`, team_id: "team-1", title: `Notiz ${number}`, path: `notiz-${number}.md`, content: ""};
  });
  await database.insert(knowledgeNotes).values(rows);

  const notes = await new SQLiteKnowledgeBaseAssistantNoteStore(database).listNotes("team-1");

  assert.equal(notes.length, 60);
  assert.equal(notes[notes.length - 1].title, "Notiz 60");
});
