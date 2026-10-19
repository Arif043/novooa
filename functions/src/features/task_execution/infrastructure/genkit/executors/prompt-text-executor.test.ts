import assert from "node:assert/strict";
import test from "node:test";
import {fieldOutputsFor, structuredSchemaFor} from "./prompt-text-executor.js";
import {definedFieldsOf} from "./structured-output-schema.js";
import {type StructuredOutputField} from "./prompt-node-types.js";

// Deckt die neue Typisierung strukturierter Prompt-Ausgabefelder ab: vorher
// baute `structuredSchemaFor` für jedes Feld hartkodiert `z.string()` —
// jetzt nutzt es Genkits typisierte Ausgabe-Unterstützung
// (`ai.generate({output: {schema}})`) mit echten number/boolean-Schemas
// samt Zod-Coercion.

function fieldFor(
  type: StructuredOutputField["type"],
  overrides: Partial<StructuredOutputField> = {},
): StructuredOutputField {
  return {name: "feld", description: "", type, ...overrides};
}

test("string-Feld verlangt weiterhin einen nicht-leeren String", () => {
  const schema = structuredSchemaFor([fieldFor("string")]);

  assert.deepEqual(schema.parse({feld: "hallo"}), {feld: "hallo"});
  assert.throws(() => schema.parse({feld: ""}));
});

test("number-Feld koerziert einen vom Modell als String gelieferten Wert", () => {
  const schema = structuredSchemaFor([fieldFor("number")]);

  assert.deepEqual(schema.parse({feld: "42"}), {feld: 42});
  assert.deepEqual(schema.parse({feld: 42}), {feld: 42});
});

test("boolean-Feld koerziert einen vom Modell als String gelieferten Wert", () => {
  const schema = structuredSchemaFor([fieldFor("boolean")]);

  assert.deepEqual(schema.parse({feld: "true"}), {feld: true});
  assert.deepEqual(schema.parse({feld: true}), {feld: true});
});

test("übernimmt die Feldbeschreibung als Schema-Beschreibung, wenn gesetzt", () => {
  const schema = structuredSchemaFor([
    fieldFor("number", {description: "Die Gesamtsumme in Euro"}),
  ]);

  const fieldSchema = (schema.shape as Record<string, {description?: string}>).feld;
  assert.equal(fieldSchema.description, "Die Gesamtsumme in Euro");
});

test("fieldOutputsFor markiert jeden Ausgabewert mit seinem Laufzeittyp", () => {
  const outputs = fieldOutputsFor({
    name: "Ada",
    alter: 36,
    aktiv: true,
  }, [fieldFor("string", {name: "name"}), fieldFor("number", {name: "alter"}), fieldFor("boolean", {name: "aktiv"})]);

  assert.deepEqual(outputs, {
    name: {type: "string", value: "Ada"},
    alter: {type: "number", value: 36},
    aktiv: {type: "boolean", value: true},
  });
});

test("zusätzliche Felder des Modells fallen weg", () => {
  const fields = [fieldFor("string", {name: "summe"}), fieldFor("string", {name: "datum"})];

  const defined = definedFieldsOf({summe: "3,24", kasse: "1", datum: "29.09."}, fields);

  assert.deepEqual(defined, {summe: "3,24", datum: "29.09."});
});

test("datetime-Feld verlangt ISO 8601 und wird ein datetime-Wert", () => {
  const field = fieldFor("datetime", {name: "faellig"});
  const schema = structuredSchemaFor([field]);

  assert.deepEqual(schema.parse({faellig: "2026-10-18T09:30:00"}), {faellig: "2026-10-18T09:30:00"});
  assert.throws(() => schema.parse({faellig: "morgen"}));
  assert.deepEqual(fieldOutputsFor({faellig: "2026-10-18"}, [field]), {faellig: {type: "datetime", value: "2026-10-18"}});
});

test("json-Feld kommt als Text und wird geparst; ungültiges JSON ist ein Schemafehler", () => {
  const field = fieldFor("json", {name: "kunde", description: "Der Kunde"});
  const fieldSchema = (structuredSchemaFor([field]).shape as Record<string, {description?: string}>).kunde;

  assert.equal(fieldSchema.description, "Der Kunde Gültiges JSON als Text.");
  assert.deepEqual(fieldOutputsFor({kunde: "{\"name\":\"Ada\"}"}, [field]), {kunde: {type: "json", value: {name: "Ada"}}});
  assert.throws(() => fieldOutputsFor({kunde: "{kaputt"}, [field]), /Das Feld „kunde“ enthält kein gültiges JSON/);
});
