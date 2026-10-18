import assert from "node:assert/strict";
import test from "node:test";
import {type ForEachNodeConfig} from "../entities/task.js";
import {err, ok} from "neverthrow";
import {nodeFailures} from "../entities/node-failures.js";
import {executeForEach} from "./for-each-executor.js";

test("executes every item serially and preserves its result order", async () => {
  const values: unknown[] = [];
  const resultOrFailure = await executeForEach({
    config: config(),
    items: {items: ["first", "second"]},
    async runGraph(_task, scope) {
      const value = scope?.iteration?.value;
      values.push(value);
      return ok([resultFor(`${value}-done`)]);
    },
  });
  const result = resultOrFailure._unsafeUnwrap();

  assert.deepEqual(values, ["first", "second"]);
  // Je Runde ein flaches Objekt aus den benannten Werten, wie in Vorlagen.
  assert.deepEqual(result, [
    {unterplan: "first-done"},
    {unterplan: "second-done"},
  ]);
});

test("uses the complete predecessor value for an empty pointer", async () => {
  const values: unknown[] = [];
  await executeForEach({
    config: {...config(), itemsPointer: ""},
    items: ["first", "second"],
    async runGraph(_task, scope) {
      values.push(scope?.iteration?.value);
      return ok([resultFor(scope?.iteration?.value)]);
    },
  });
  assert.deepEqual(values, ["first", "second"]);
});

test("fails fast and adds the failing item index to the inner failure", async () => {
  const calls: unknown[] = [];
  const resultOrFailure = await executeForEach({
    config: config(),
    items: {items: ["first", "second", "third"]},
    async runGraph(_task, scope) {
      const value = scope?.iteration?.value;
      calls.push(value);
      if (value === "second") return err(nodeFailures.settingMissing("recipient"));
      return ok([resultFor(value)]);
    },
  });

  assert.deepEqual(resultOrFailure._unsafeUnwrapErr().details, {setting: "recipient", iteration: "1"});
  assert.deepEqual(calls, ["first", "second"]);
});

test("rejects pausing primitives in the embedded graph", async () => {
  const resultOrFailure = await executeForEach({
    config: config({primitive: "humanApproval"}),
    items: {items: ["first"]},
    async runGraph() {
      return ok([]);
    },
  });

  assert.deepEqual(resultOrFailure._unsafeUnwrapErr().details, {reason: "pausingBlock"});
});

test("a pointer to something other than a list is a failure", async () => {
  const resultOrFailure = await executeForEach({
    config: config(), items: {items: "kein Array"}, async runGraph() { return ok([]); },
  });

  assert.equal(resultOrFailure._unsafeUnwrapErr().code, "valueTypeMismatch");
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
        outputs: [{key: "value", name: "unterplan", showOnCanvas: true}],
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
