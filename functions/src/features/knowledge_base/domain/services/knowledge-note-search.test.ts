import assert from "node:assert/strict";
import test from "node:test";
import {searchKnowledgeNotes} from "./knowledge-note-search.js";

const note = (id: string, title: string, content = "") => ({id, title, path: `${id}.md`, content});

test("ranks title matches before content matches and keeps the order otherwise", () => {
  const notes = [
    note("a", "Ablauf", "Die Mahnung folgt nach 14 Tagen."),
    note("b", "Mahnung"),
    note("c", "Kunden", "Mahnung nur schriftlich."),
  ];

  assert.deepEqual(searchKnowledgeNotes(notes, "mahnung", 20).map((found) => found.id), ["b", "a", "c"]);
});

test("matches regardless of case, including umlauts", () => {
  const notes = [note("a", "Übergabe an Buchhaltung")];

  assert.deepEqual(searchKnowledgeNotes(notes, "übergabe", 20).map((found) => found.id), ["a"]);
});

test("an empty query lists notes up to the limit", () => {
  const notes = [note("a", "A"), note("b", "B"), note("c", "C")];

  assert.deepEqual(searchKnowledgeNotes(notes, "  ", 2).map((found) => found.id), ["a", "b"]);
});
