import assert from "node:assert/strict";
import test from "node:test";
import {SQLiteKnowledgeBaseAssistantNoteStore} from "./sqlite-knowledge-base-assistant-note-store.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";

test("lists local assistant notes for the active team", async () => {
  const store = new SQLiteKnowledgeBaseAssistantNoteStore(
    databaseWithRows([{id: "note-1", title: "Plan", path: "plan.md", content: "Inhalt"}]),
  );

  const notes = await store.listNotes("team-1");

  assert.deepEqual(notes, [{
    id: "note-1",
    title: "Plan",
    path: "plan.md",
    content: "Inhalt",
  }]);
});

test("returns no local assistant note when it is absent", async () => {
  const store = new SQLiteKnowledgeBaseAssistantNoteStore(databaseWithRows([]));

  const note = await store.findNote("team-1", "missing");

  assert.equal(note, null);
});

function databaseWithRows(rows: SqlRow[]): LocalSqlDatabase {
  return {
    get: async <T extends SqlRow>() => rows[0] as T | undefined ?? null,
    all: async <T extends SqlRow>() => rows as T[],
    run: async () => undefined,
    transaction: async <T>(operation: () => Promise<T>) => operation(),
  };
}
