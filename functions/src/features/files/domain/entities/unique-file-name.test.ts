import assert from "node:assert/strict";
import test from "node:test";
import {uniqueFileNameFor} from "./unique-file-name.js";

test("a free name stays as it is", () => {
  assert.equal(uniqueFileNameFor("Rechnungen (Kopie).xlsx", new Set(["Rechnungen.xlsx"])), "Rechnungen (Kopie).xlsx");
});

test("a taken name gets the next free counter before the extension", () => {
  const taken = new Set(["Rechnungen (Kopie).xlsx", "Rechnungen (Kopie) (2).xlsx"]);

  assert.equal(uniqueFileNameFor("Rechnungen (Kopie).xlsx", taken), "Rechnungen (Kopie) (3).xlsx");
});

test("names without an extension and dot files keep their whole name as the base", () => {
  assert.equal(uniqueFileNameFor("README", new Set(["README"])), "README (2)");
  assert.equal(uniqueFileNameFor(".env", new Set([".env"])), ".env (2)");
});
