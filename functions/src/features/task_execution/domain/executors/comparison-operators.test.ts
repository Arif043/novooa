import assert from "node:assert/strict";
import test from "node:test";
import {ConditionOperandError} from "../entities/condition-operand-error.js";
import {comparisonOperators as is} from "./comparison-operators.js";

process.env.TZ = "Europe/Berlin";

const table = {columns: ["Name"], rows: [["A"], ["B"], ["C"]]};
const image = {fileId: "f1", versionId: "v1", displayName: "scan.jpg", contentType: "image/jpeg", sizeBytes: 10};

test("Text: enthält nicht, beginnt mit, endet mit", () => {
  assert.equal(is.notContains("Rechnung 42", "Mahnung"), true);
  assert.equal(is.startsWith("Rechnung 42", "Rech"), true);
  assert.equal(is.endsWith("Rechnung 42", "42"), true);
});

test("Leere gilt für Text, Liste, Objekt, Tabelle und fehlende Werte", () => {
  for (const empty of ["  ", [], {}, {columns: ["A"], rows: []}, undefined, null]) {
    assert.equal(is.isEmpty(empty, ""), true, JSON.stringify(empty));
  }
  assert.equal(is.isNotEmpty(table, ""), true);
  assert.equal(is.isNotEmpty(image, ""), true);
});

test("Wahrheitswerte auch als Text", () => {
  assert.equal(is.isTrue(true, ""), true);
  assert.equal(is.isFalse("false", ""), true);
  assert.throws(() => is.isTrue("ja", ""), ConditionOperandError);
});

test("Zahl-Operatoren vergleichen bei Tabellen die Zeilenanzahl", () => {
  assert.equal(is.greaterThan(table, "2"), true);
  assert.equal(is.lessThanOrEqual(3.24, "50"), true);
  assert.throws(() => is.greaterThan("abc", "2"), /„größer als“ braucht eine Zahl, erhalten: „abc“/);
});

test("Datum: vor, nach und ist am in der Zeitzone der Runtime", () => {
  assert.equal(is.before("2025-12-31T23:00:00.000Z", "2026-01-01"), false);
  assert.equal(is.after("2026-10-18T08:00:00.000Z", "2026-10-18"), true);
  // 23:30 UTC ist in Berlin bereits der nächste Tag.
  assert.equal(is.sameDay("2026-10-17T23:30:00.000Z", "2026-10-18"), true);
  assert.throws(() => is.before("abc", "2026-01-01"), /„vor“ braucht ein Datum/);
});

test("enthält: Liste nach Element, Objekt nach Schlüssel, Text nach Teiltext", () => {
  assert.equal(is.contains(["a", 2], "2"), true);
  assert.equal(is.contains({kunde: "Meier"}, "kunde"), true);
  assert.equal(is.contains({kunde: "Meier"}, "Meier"), false);
  assert.equal(is.contains("Hallo Welt", "Welt"), true);
});

test("Dateityp exakt oder mit Platzhalter", () => {
  assert.equal(is.contentTypeIs(image, "image/jpeg"), true);
  assert.equal(is.contentTypeIs(image, "image/*"), true);
  assert.equal(is.contentTypeIs(image, "audio/*"), false);
  assert.throws(() => is.contentTypeIs("scan.jpg", "image/*"), /braucht eine Datei/);
});
