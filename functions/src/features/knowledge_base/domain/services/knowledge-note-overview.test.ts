import assert from "node:assert/strict";
import test from "node:test";
import {knowledgeNoteOverview} from "./knowledge-note-overview.js";

test("counts links and backlinks per note and reveals orphans", () => {
  const notes = [
    {id: "buchhaltung", title: "Buchhaltung", path: "buchhaltung.md", content: "- [[Mahnung]]\n- [[Fristen]]\n- [[Fristen|nochmal]]"},
    {id: "mahnung", title: "Mahnung", path: "mahnung.md", content: "Siehe [Fristen](fristen.md) und [[Mahnung]]."},
    {id: "fristen", title: "Fristen", path: "fristen.md", content: "Keine Links."},
    {id: "waise", title: "Waise", path: "waise.md", content: "[[Buchhaltung]]"},
  ];

  assert.deepEqual(knowledgeNoteOverview(notes), [
    {id: "buchhaltung", title: "Buchhaltung", links: 2, backlinks: 1},
    {id: "mahnung", title: "Mahnung", links: 1, backlinks: 1},
    {id: "fristen", title: "Fristen", links: 0, backlinks: 2},
    {id: "waise", title: "Waise", links: 1, backlinks: 0},
  ]);
});
