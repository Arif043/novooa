import assert from "node:assert/strict";
import test from "node:test";
import {type ForEachNodeConfig} from "../entities/task.js";
import {executeForEach} from "./for-each-executor.js";

test("executes every item serially and preserves its result order", async () => {
  const values: unknown[] = [];
  const result = await executeForEach({
    config: config(),
    items: {items: ["first", "second"]},
    async runGraph(_task, input) {
      const value = input.scope?.iteration?.value;
      values.push(value);
      return [resultFor(`${value}-done`)];
    },
  });

  assert.deepEqual(values, ["first", "second"]);
  assert.deepEqual(result, [
    {unterplan: {value: "first-done"}},
    {unterplan: {value: "second-done"}},
  ]);
});

test("uses the complete predecessor value for an empty pointer", async () => {
  const values: unknown[] = [];
  await executeForEach({
    config: {...config(), itemsPointer: ""},
    items: ["first", "second"],
    async runGraph(_task, input) {
      values.push(input.scope?.iteration?.value);
      return [resultFor(input.scope?.iteration?.value)];
    },
  });
  assert.deepEqual(values, ["first", "second"]);
});

test("fails fast and includes the failing item index", async () => {
  const calls: unknown[] = [];
  await assert.rejects(
    executeForEach({
        config: config(),
      items: {items: ["first", "second", "third"]},
      async runGraph(_task, input) {
        const value = input.scope?.iteration?.value;
        calls.push(value);
        if (value === "second") throw new Error("ungültiger Wert");
        return [resultFor(value)];
      },
    }),
    /Iteration 1 ist fehlgeschlagen: ungültiger Wert/,
  );
  assert.deepEqual(calls, ["first", "second"]);
});

test("rejects pausing primitives in the embedded graph", async () => {
  const invalidConfig = config({primitive: "humanApproval"});
  await assert.rejects(
    executeForEach({
        config: invalidConfig,
      items: {items: ["first"]},
      async runGraph() {
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
      nodes: [{
        id: "sub-1",
        primitive: (node?.primitive ?? "stringInput") as "humanApproval",
        title: "Unterplan",
        description: "",
        outputName: "unterplan",
      }],
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
