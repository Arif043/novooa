import assert from "node:assert/strict";
import test from "node:test";
import {knowledgeNoteFilenames} from "./knowledge-note-filenames.js";

const note = (noteId: string, title: string, path = "") => ({noteId, title, path});

test("uses the title as file name, keeping umlauts and spaces", () => {
  const filenames = knowledgeNoteFilenames([note("n1", "Übergabe an die Buchhaltung")]);

  assert.equal(filenames.get("n1"), "knowledge/Übergabe an die Buchhaltung.md");
});

test("replaces characters that are not allowed in file names and leaves no path", () => {
  const filenames = knowledgeNoteFilenames([note("n1", "Kosten: 2026/Q1?"), note("n2", "../geheim"), note("n3", "Plan.md")]);

  assert.deepEqual([...filenames.values()], ["knowledge/Kosten- 2026-Q1-.md", "knowledge/-geheim.md", "knowledge/Plan.md"]);
});

test("falls back to the path and then the note ID for empty titles", () => {
  const filenames = knowledgeNoteFilenames([note("n1", "  ", "ordner/leitfaden.md"), note("n2", "", "")]);

  assert.deepEqual([...filenames.values()], ["knowledge/leitfaden.md", "knowledge/n2.md"]);
});
