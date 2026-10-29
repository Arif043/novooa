import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit";
import {defineReadKnowledgeNoteTool} from "./read-knowledge-note-tool.js";

const notesByTeam: Record<string, {id: string; title: string; path: string; content: string}[]> = {
  "team-1": [
    {id: "mahnung", title: "Mahnung", path: "mahnung.md", content: "Siehe [[Fristen]]."},
    {id: "fristen", title: "Fristen", path: "fristen.md", content: "Fristen der Buchhaltung."},
  ],
  "team-2": [{id: "fremd", title: "Fremd", path: "fremd.md", content: "[[Fristen]]"}],
};

const readTool = defineReadKnowledgeNoteTool(genkit({}), {
  noteStore: {listNotes: async (teamId) => notesByTeam[teamId] ?? []},
  teamContextStore: {currentTeamIdForUid: async (uid) => (uid === "user-1" ? "team-1" : "team-2")},
});

const asUser = (actorId: string) => ({context: {assistant: {actorId}}});

test("returns a note with its links and backlinks inside the team", async () => {
  const output = await readTool({noteId: "fristen"}, asUser("user-1"));

  assert.equal(output.found, true);
  assert.deepEqual(output.note?.links, []);
  assert.deepEqual(output.note?.backlinks, [{id: "mahnung", title: "Mahnung"}]);
});

test("does not read notes of another team", async () => {
  const output = await readTool({noteId: "fremd"}, asUser("user-1"));

  assert.deepEqual(output, {found: false, note: null});
});
