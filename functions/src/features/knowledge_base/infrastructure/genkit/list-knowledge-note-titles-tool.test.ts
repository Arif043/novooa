import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit";
import {defineListKnowledgeNoteTitlesTool} from "./list-knowledge-note-titles-tool.js";

const note = (index: number) => ({id: `n${index}`, title: `Notiz ${index}`, path: `n${index}.md`, content: ""});

function toolWith(notesByTeam: Record<string, ReturnType<typeof note>[]>) {
  return defineListKnowledgeNoteTitlesTool(genkit({}), {
    noteStore: {listNotes: async (teamId) => notesByTeam[teamId] ?? []},
    teamContextStore: {currentTeamIdForUid: async () => "team-1"},
  });
}

const asUser = {context: {assistant: {actorId: "user-1"}}};

test("lists every title of the team without content", async () => {
  const output = await toolWith({"team-1": [note(1), note(2)], "team-2": [note(3)]})({}, asUser);

  assert.deepEqual(output, {
    total: 2,
    truncated: false,
    notes: [
      {id: "n1", title: "Notiz 1", links: 0, backlinks: 0},
      {id: "n2", title: "Notiz 2", links: 0, backlinks: 0},
    ],
  });
});

test("reports when a very large knowledge base is cut off", async () => {
  const output = await toolWith({"team-1": Array.from({length: 501}, (_, index) => note(index))})({}, asUser);

  assert.equal(output.total, 501);
  assert.equal(output.truncated, true);
  assert.equal(output.notes.length, 500);
});
