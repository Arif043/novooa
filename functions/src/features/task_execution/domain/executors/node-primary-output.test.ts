import assert from "node:assert/strict";
import test from "node:test";
import {type NodeExecutionResult} from "../entities/task.js";
import {textOutputFromResult} from "./node-executor.js";

function resultWith(outputs: NodeExecutionResult["outputs"]): NodeExecutionResult {
  return {nodeId: "node.2", primitive: "prompt", status: "executed", outputs};
}

test("der Hauptwert ist value, wenn es ihn gibt", () => {
  const result = resultWith({
    value: {type: "string", value: "Hallo"},
    sender: {type: "string", value: "meier@example.com"},
  });

  assert.equal(textOutputFromResult(result), "Hallo");
});

test("ohne value stehen alle Felder zusammen für den Baustein", () => {
  const result = resultWith({
    Filialname: {type: "string", value: "PENNY"},
    Gesamtbetrag: {type: "number", value: 3.24},
  });

  assert.equal(textOutputFromResult(result), "{\"Filialname\":\"PENNY\",\"Gesamtbetrag\":3.24}");
});

test("ein einzelnes Feld ist selbst der Hauptwert", () => {
  assert.equal(textOutputFromResult(resultWith({Summe: {type: "number", value: 3}})), "3");
});
