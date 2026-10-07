import assert from "node:assert/strict";
import test from "node:test";
import {knowledgeLinksFrom} from "./knowledge-link-extractor.js";

const notes = [
  {id: "note-1", title: "Leitfaden", path: "wissen/leitfaden.md"},
  {id: "note-2", title: "Über uns", path: "ueber uns.md"},
];

test("resolves wiki aliases, headings and block references without duplicate IDs", () => {
  const content = "[[LEITFADEN]] [[note-1#Kapitel|Lesen]] [[wissen/leitfaden^block]] [[wissen/leitfaden.md]]";
  assert.deepEqual(knowledgeLinksFrom(content, notes), ["note-1"]);
});

test("resolves Markdown links by ID, title, path and URI-encoded aliases", () => {
  for (const target of ["note-1", "LEITFADEN", "wissen/leitfaden", "wissen/leitfaden.md"]) {
    assert.deepEqual(knowledgeLinksFrom(`[Lesen](${target})`, notes), ["note-1"]);
  }
  assert.deepEqual(knowledgeLinksFrom("[Über](%C3%9Cber%20uns)", notes), ["note-2"]);
});

test("unknown, external, empty and malformed targets do not produce links", () => {
  const content = "[[Unbekannt]] [[#Kapitel]] [Web](https://example.org) [Leer]() [Kaputt](%ZZ)";
  assert.deepEqual(knowledgeLinksFrom(content, notes), []);
});

test("matching uses current aliases and keeps ID references after a rename", () => {
  const renamed = [{...notes[0], title: "Neu", path: "neu.md"}];
  assert.deepEqual(knowledgeLinksFrom("[[Leitfaden]]", renamed), []);
  assert.deepEqual(knowledgeLinksFrom("[[Neu]] [[note-1]]", renamed), ["note-1"]);
});

test("shared titles resolve to every matching note, while repeated links remain unique", () => {
  const sameTitle = [{...notes[0], id: "first"}, {...notes[0], id: "second"}];
  assert.deepEqual(knowledgeLinksFrom("[[Leitfaden]] [[Leitfaden]]", sameTitle), ["first", "second"]);
});
