import assert from "node:assert/strict";
import test from "node:test";
import {type ComparisonOperator} from "../entities/task.js";
import {comparisonOperators} from "./comparison-operators.js";

process.env.TZ = "Europe/Berlin";

const table = {columns: ["Name"], rows: [["A"], ["B"], ["C"]]};
const image = {fileId: "f1", versionId: "v1", displayName: "scan.jpg", contentType: "image/jpeg", sizeBytes: 10};

function is(operator: ComparisonOperator, left: unknown, right: unknown = ""): boolean {
  return comparisonOperators[operator](left, right)._unsafeUnwrap();
}

function failureOf(operator: ComparisonOperator, left: unknown, right: unknown = "") {
  return comparisonOperators[operator](left, right)._unsafeUnwrapErr();
}

test("Text: enthält nicht, beginnt mit, endet mit", () => {
  assert.equal(is("notContains", "Rechnung 42", "Mahnung"), true);
  assert.equal(is("startsWith", "Rechnung 42", "Rech"), true);
  assert.equal(is("endsWith", "Rechnung 42", "42"), true);
});

test("Leere gilt für Text, Liste, Objekt, Tabelle und fehlende Werte", () => {
  for (const empty of ["  ", [], {}, {columns: ["A"], rows: []}, undefined, null]) {
    assert.equal(is("isEmpty", empty), true, JSON.stringify(empty));
  }
  assert.equal(is("isNotEmpty", table), true);
  assert.equal(is("isNotEmpty", image), true);
});

test("Wahrheitswerte auch als Text", () => {
  assert.equal(is("isTrue", true), true);
  assert.equal(is("isFalse", "false"), true);
  assert.deepEqual(failureOf("isTrue", "ja").details, {operator: "isTrue", expected: "boolean", received: "ja"});
});

test("Zahl-Operatoren vergleichen bei Tabellen die Zeilenanzahl", () => {
  assert.equal(is("greaterThan", table, "2"), true);
  assert.equal(is("lessThanOrEqual", 3.24, "50"), true);
});

test("ein unpassender Wert ist eine Failure mit Code und Feldern", () => {
  const failure = failureOf("greaterThan", "abc", "2");

  assert.equal(failure.code, "conditionOperandMismatch");
  assert.deepEqual(failure.details, {operator: "greaterThan", expected: "number", received: "abc"});
  assert.equal(failure.technicalMessage, "conditionOperandMismatch: operator=greaterThan expected=number received=\"abc\"");
});

test("Datum: vor, nach und ist am in der Zeitzone der Runtime", () => {
  assert.equal(is("before", "2025-12-31T23:00:00.000Z", "2026-01-01"), false);
  assert.equal(is("after", "2026-10-18T08:00:00.000Z", "2026-10-18"), true);
  // 23:30 UTC ist in Berlin bereits der nächste Tag.
  assert.equal(is("sameDay", "2026-10-17T23:30:00.000Z", "2026-10-18"), true);
  assert.equal(failureOf("before", "29.09.2026", "2026-01-01").expected, "date");
});

test("enthält: Liste nach Element, Objekt nach Schlüssel, Text nach Teiltext", () => {
  assert.equal(is("contains", ["a", 2], "2"), true);
  assert.equal(is("contains", {kunde: "Meier"}, "kunde"), true);
  assert.equal(is("contains", {kunde: "Meier"}, "Meier"), false);
  assert.equal(is("contains", "Hallo Welt", "Welt"), true);
});

test("Dateityp exakt oder mit Platzhalter", () => {
  assert.equal(is("contentTypeIs", image, "image/jpeg"), true);
  assert.equal(is("contentTypeIs", image, "image/*"), true);
  assert.equal(is("contentTypeIs", image, "audio/*"), false);
  assert.equal(failureOf("contentTypeIs", "scan.jpg", "image/*").expected, "file");
});
