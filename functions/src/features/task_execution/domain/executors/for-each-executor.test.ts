import assert from "node:assert/strict";
import test from "node:test";
import {type ForEachNodeConfig} from "../entities/task.js";
import {executeForEach} from "./for-each-executor.js";

test("executes every item serially and preserves its result order", async () => {
  const values: unknown[] = [];
  const result = await executeForEach({
    nodeId: "each-1",
    config: config(),
    inputValue: {type: "json", value: {items: ["first", "second"]}},
    async runSubgraph(_task, initialValue) {
      values.push(initialValue.value);
      return [resultFor(`${initialValue.value}-done`)];
    },
  });

  assert.deepEqual(values, ["first", "second"]);
  assert.deepEqual(result, ["first-done", "second-done"]);
});

test("fails fast and includes the failing item index", async () => {
  const calls: unknown[] = [];
  await assert.rejects(
    executeForEach({
      nodeId: "each-1",
      config: config(),
      inputValue: {type: "json", value: {items: ["first", "second", "third"]}},
      async runSubgraph(_task, initialValue) {
        calls.push(initialValue.value);
        if (initialValue.value === "second") throw new Error("ungültiger Wert");
        return [resultFor(initialValue.value)];
      },
    }),
    /Iteration 1 ist fehlgeschlagen: ungültiger Wert/,
  );
  assert.deepEqual(calls, ["first", "second"]);
});

test("rejects pausing primitives in the subgraph", async () => {
  const invalidConfig = config({primitive: "humanApproval"});
  await assert.rejects(
    executeForEach({
      nodeId: "each-1",
      config: invalidConfig,
      inputValue: {type: "json", value: {items: ["first"]}},
      async runSubgraph() {
        return [];
      },
    }),
    /Pausierende Bausteine/,
  );
});

function config(node?: {primitive: string}): ForEachNodeConfig {
  return {
    primitive: "forEach",
    itemsPointer: "/items",
    graph: {
      nodes: node ? [{
        id: "sub-1",
        primitive: node.primitive as "humanApproval",
        title: "Unterplan",
        description: "",
        referenceName: "unterplan",
      }] : [],
      edges: [],
    },
  };
}

function resultFor(value: unknown) {
  return {
    nodeId: "sub-1",
    primitive: "stringInput" as const,
    status: "executed" as const,
    outputs: {value: {type: "json" as const, value}},
  };
}
