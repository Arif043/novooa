import assert from "node:assert/strict";
import test from "node:test";
import {fileWriteSitesOf} from "./file-write-sites.js";

function node(id: string, config: Record<string, unknown>) {
  return {id, primitive: String(config.primitive), config};
}

test("erkennt Schreibstellen eines Datei-Bausteins", () => {
  const sites = fileWriteSitesOf({nodes: [
    node("w", {primitive: "writeFile", fileName: "a.txt", contentType: "text/plain", folderId: "ordner"}),
    node("v", {primitive: "writeFile", fileName: "b.txt", contentType: "text/plain", fileId: "f1"}),
  ] as never});

  assert.deepEqual(sites[0].placement, {kind: "folder", folderId: "ordner"});
  assert.equal(sites[0].contentKind, "text");
  assert.equal(sites[0].contentKindIsCertain, false);
  assert.deepEqual(sites[1].placement, {kind: "existingFile", fileId: "f1"});
});

test("ohne Verzeichnis wird in der obersten Ebene geschrieben", () => {
  const [site] = fileWriteSitesOf({nodes: [
    node("w", {primitive: "writeFile", fileName: "a.txt", contentType: ""}),
  ] as never});

  assert.deepEqual(site.placement, {kind: "folder", folderId: null});
  assert.equal(site.contentKind, "text");
});

test("findet Schreibstellen in Verzweigungen und Schleifen", () => {
  const inner = {nodes: [node("w", {primitive: "writeFile", fileName: "x", contentType: "text/plain"})], edges: []};
  const sites = fileWriteSitesOf({nodes: [
    node("c", {primitive: "conditionalFlow", branches: [{id: "b", graph: inner}]}),
    node("f", {primitive: "forEach", graph: inner}),
  ] as never});

  assert.equal(sites.length, 2);
});

test("Bild-Prompts und Sprachausgabe schreiben sicher in die oberste Ebene", () => {
  const sites = fileWriteSitesOf({nodes: [
    node("p", {primitive: "prompt", outputType: "image"}),
    node("s", {primitive: "textToSpeech"}),
    node("t", {primitive: "prompt", outputType: "text"}),
  ] as never});

  assert.equal(sites.length, 2);
  assert.deepEqual(sites.map((site) => site.contentKind), ["image", "audio"]);
  assert.ok(sites.every((site) => site.contentKindIsCertain));
});

test("jedes Datei-Feld der Teamarbeit ist eine Schreibstelle in der obersten Ebene", () => {
  const sites = fileWriteSitesOf({nodes: [
    node("t", {primitive: "teamwork", outputFields: [
      {name: "bericht", type: "file", fileFormat: "markdown"},
      {name: "summe", type: "number"},
      {name: "liste", type: "file", fileFormat: "csv"},
    ]}),
  ] as never});

  assert.equal(sites.length, 2);
  assert.ok(sites.every((site) => site.placement.kind === "folder" && site.placement.folderId === null));
  assert.ok(sites.every((site) => site.contentKindIsCertain));
});
