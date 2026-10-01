import assert from "node:assert/strict";
import test from "node:test";
import {fileContentKindOf} from "./file-content-kind.js";

test("ordnet MIME-Types ihrer Kategorie zu", () => {
  assert.equal(fileContentKindOf("text/markdown"), "text");
  assert.equal(fileContentKindOf("application/json"), "text");
  assert.equal(fileContentKindOf("image/png"), "image");
  assert.equal(fileContentKindOf("video/mp4"), "video");
  assert.equal(fileContentKindOf("audio/mpeg"), "audio");
  assert.equal(fileContentKindOf("application/pdf"), "pdf");
  assert.equal(fileContentKindOf("application/zip"), "other");
});

test("erkennt xlsx an der Endung, wenn der MIME-Type generisch ist", () => {
  assert.equal(fileContentKindOf("application/octet-stream", "Zahlen.XLSX"), "spreadsheet");
  assert.equal(fileContentKindOf("", "Zahlen.xlsx"), "spreadsheet");
  assert.equal(fileContentKindOf("application/octet-stream", "daten.bin"), "other");
});
