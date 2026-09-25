import assert from "node:assert/strict";
import test from "node:test";
import {nodeOutputValueSchema} from "./task-definition.js";

// Deckt eine zuvor gefundene Inkonsistenz ab: `table` ist ein gültiger
// `NodeOutputValue`-Typ (siehe `workflow-value.ts`, von
// `table-from-collection-node-executor.ts` erzeugt), fehlte aber im
// Zod-Schema — ein Tabellen-Output hätte die Validierung nicht bestanden,
// obwohl der TypeScript-Typ ihn als gültig ausweist.
test("akzeptiert einen table-typisierten Workflow-Ausgabewert", () => {
  const value = {
    type: "table",
    value: {
      columns: ["Name", "Alter"],
      rows: [
        ["Ada", 36],
        ["Alan", 41],
      ],
    },
  };

  const parsed = nodeOutputValueSchema.parse(value);

  assert.deepEqual(parsed, value);
});

test("lehnt einen table-Wert mit falsch typisierten Spalten ab", () => {
  const value = {
    type: "table",
    value: {columns: [1, 2], rows: []},
  };

  assert.throws(() => nodeOutputValueSchema.parse(value));
});

test("akzeptiert weiterhin die übrigen bekannten Ausgabewert-Typen", () => {
  assert.doesNotThrow(() =>
    nodeOutputValueSchema.parse({type: "string", value: "text"}),
  );
  assert.doesNotThrow(() =>
    nodeOutputValueSchema.parse({type: "boolean", value: true}),
  );
  assert.doesNotThrow(() =>
    nodeOutputValueSchema.parse({type: "json", value: {a: 1}}),
  );
});
