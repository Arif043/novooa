import assert from "node:assert/strict";
import test from "node:test";
import {type DocumentData} from "../entities/document.js";
import {parseCsv, writeCsv} from "./csv-table.js";
import {normalizeFieldNames} from "./document-field-names.js";
import {exportDocuments, inferredValue, parseDocumentImport} from "./document-table-codec.js";

test("reads quoted cells, line breaks inside cells, CRLF and a byte order mark", () => {
  const records = parseCsv("﻿name,notiz\r\n\"ACME, AG\",\"Zeile 1\nZeile 2\"\r\n\"Er sagt \"\"Hallo\"\"\",\r\n");

  assert.deepEqual(records.map((record) => record.cells), [
    ["name", "notiz"], ["ACME, AG", "Zeile 1\nZeile 2"], ["Er sagt \"Hallo\"", ""],
  ]);
  assert.deepEqual(records.map((record) => record.line), [1, 2, 4], "Zeilennummer, an der der Datensatz beginnt");
});

test("detects semicolons as delimiter like German Excel exports", () => {
  const records = parseCsv("name;betrag\nA;1,5\n");

  assert.deepEqual(records[1]?.cells, ["A", "1,5"]);
});

test("writes CSV that reads back to the same cells", () => {
  const rows = [["ACME, AG", " Leerzeichen "], ["mit \"Zitat\"", "a;b"], ["Zeile\nzwei", ""]];

  const written = writeCsv(["name", "notiz"], rows);

  assert.ok(written.startsWith("﻿"));
  assert.deepEqual(parseCsv(written).slice(1).map((record) => record.cells), rows);
});

test("normalizes column names into unique queryable fields", () => {
  const {fields, renamed} = normalizeFieldNames(["Kunden Name", "Größe (cm)", "name", "1. Quartal", "", "Kunden-Name", "Café"]);

  assert.deepEqual(fields, ["Kunden_Name", "Groesse_cm", "name", "feld_1_Quartal", "feld", "Kunden_Name_2", "Cafe"]);
  assert.equal(renamed.length, 6, "nur geänderte Namen werden gemeldet");
});

test("infers numbers and booleans but keeps leading zeros as text", () => {
  assert.deepEqual(["42", "-1.5", "1e3", "true", "false", "01067", "1,5", "abc"].map(inferredValue),
    [42, -1.5, 1000, true, false, "01067", "1,5", "abc"]);
});

test("imports CSV rows, omits empty cells and reports extra values with their line", () => {
  const imported = parseDocumentImport("csv", "Kunden Name,PLZ,aktiv\nAnna,01067,true\nBen,,false,zu viel\n");

  assert.deepEqual(imported.items, [{Kunden_Name: "Anna", PLZ: "01067", aktiv: true}, {Kunden_Name: "Ben", aktiv: false}]);
  assert.deepEqual(imported.renamed, [{from: "Kunden Name", to: "Kunden_Name"}]);
  assert.deepEqual(imported.issues, ["Zeile 3: mehr Werte als Spalten in der Kopfzeile."]);
});

test("imports JSON lists and reports entries that are not objects", () => {
  const imported = parseDocumentImport("json", JSON.stringify([{"Name": "A", "tags": ["x"]}, 5, {"nested": {"a": 1}}]));

  assert.deepEqual(imported.items, [{Name: "A", tags: ["x"]}, {nested: {a: 1}}]);
  assert.deepEqual(imported.fields, ["Name", "tags", "nested"]);
  assert.deepEqual(imported.issues, ["Eintrag 2: ist kein Objekt."]);
});

test("reports unreadable files instead of throwing", () => {
  assert.deepEqual(parseDocumentImport("json", "{kein json").issues, ["Die Datei enthält kein gültiges JSON."]);
  assert.deepEqual(parseDocumentImport("json", "{}").issues, ["Die JSON-Datei muss eine Liste von Objekten enthalten."]);
  assert.deepEqual(parseDocumentImport("csv", "a\n\"offen").issues, ["Zeile 2: Ein Anführungszeichen wird nicht geschlossen."]);
  assert.deepEqual(parseDocumentImport("csv", "").issues, ["Die Datei enthält keine Kopfzeile."]);
});

test("refuses more documents than one import may create", () => {
  const imported = parseDocumentImport("csv", "n\n" + "1\n".repeat(5001));

  assert.equal(imported.items.length, 5000);
  assert.match(imported.issues[0] ?? "", /5001 Datensätze/);
});

test("exports CSV with sorted columns and JSON as a list", () => {
  const documents: DocumentData[] = [{name: "A", betrag: 10}, {name: "B", adresse: {ort: "Berlin"}}];

  const csv = exportDocuments("csv", documents);
  const json = exportDocuments("json", documents);

  assert.equal(csv, "﻿adresse,betrag,name\r\n,10,A\r\n\"{\"\"ort\"\":\"\"Berlin\"\"}\",,B\r\n");
  assert.deepEqual(JSON.parse(json), documents);
  assert.deepEqual(parseDocumentImport("json", json).items, documents, "JSON-Export lässt sich unverändert importieren");
});
