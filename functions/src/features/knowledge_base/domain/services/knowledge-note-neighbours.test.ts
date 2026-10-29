import assert from "node:assert/strict";
import test from "node:test";
import {knowledgeNoteNeighbours} from "./knowledge-note-neighbours.js";

const notes = [
  {id: "mahnung", title: "Mahnung", path: "mahnung.md", content: "Siehe [[Fristen]] und [Kunden](kunden.md)."},
  {id: "fristen", title: "Fristen", path: "fristen.md", content: "Gehört zu: [[Buchhaltung]]"},
  {id: "kunden", title: "Kunden", path: "kunden.md", content: "Keine Links."},
  {id: "buchhaltung", title: "Buchhaltung", path: "buchhaltung.md", content: "- [[Mahnung]]\n- [[fristen|Fristen]]"},
];

test("lists the notes a note links to, by title or path", () => {
  const {links} = knowledgeNoteNeighbours(notes[0], notes);

  assert.deepEqual(links, [{id: "fristen", title: "Fristen"}, {id: "kunden", title: "Kunden"}]);
});

test("lists the notes that link to a note", () => {
  const {backlinks} = knowledgeNoteNeighbours(notes[1], notes);

  assert.deepEqual(backlinks, [{id: "mahnung", title: "Mahnung"}, {id: "buchhaltung", title: "Buchhaltung"}]);
});

test("a note without links has no neighbours and never links to itself", () => {
  const selfLinking = {id: "selbst", title: "Selbst", path: "selbst.md", content: "[[Selbst]]"};

  assert.deepEqual(knowledgeNoteNeighbours(selfLinking, [selfLinking]), {links: [], backlinks: []});
});
