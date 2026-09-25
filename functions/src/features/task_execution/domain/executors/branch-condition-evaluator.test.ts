import assert from "node:assert/strict";
import test from "node:test";
import {evaluateBranchCondition, selectConditionedBranch} from "./branch-condition-evaluator.js";
import {type BranchCondition, type ConditionalBranch} from "../entities/task.js";

function resolverFor(values: Record<string, unknown>) {
  return (template: string): unknown => values[template] ?? template;
}

test("equals koerziert einen numerischen String gegen eine Zahl", () => {
  const condition: BranchCondition = {
    kind: "comparison", left: "{{x}}", operator: "equals", right: "42",
  };

  assert.equal(evaluateBranchCondition(condition, resolverFor({"{{x}}": 42})), true);
  assert.equal(evaluateBranchCondition(condition, resolverFor({"{{x}}": 43})), false);
});

test("equals koerziert einen Boolean-String gegen einen echten Boolean", () => {
  const condition: BranchCondition = {
    kind: "comparison", left: "{{x}}", operator: "equals", right: "true",
  };

  assert.equal(evaluateBranchCondition(condition, resolverFor({"{{x}}": true})), true);
  assert.equal(evaluateBranchCondition(condition, resolverFor({"{{x}}": false})), false);
});

test("notEquals ist die Negation von equals", () => {
  const condition: BranchCondition = {
    kind: "comparison", left: "{{x}}", operator: "notEquals", right: "42",
  };

  assert.equal(evaluateBranchCondition(condition, resolverFor({"{{x}}": 42})), false);
  assert.equal(evaluateBranchCondition(condition, resolverFor({"{{x}}": 43})), true);
});

test("contains prüft eine Teilzeichenkette", () => {
  const condition: BranchCondition = {
    kind: "comparison", left: "{{text}}", operator: "contains", right: "Welt",
  };

  assert.equal(
    evaluateBranchCondition(condition, resolverFor({"{{text}}": "Hallo Welt"})),
    true,
  );
  assert.equal(
    evaluateBranchCondition(condition, resolverFor({"{{text}}": "Hallo"})),
    false,
  );
});

test("greaterThan/lessThan koerzieren String-Zahlen für den Vergleich", () => {
  const greaterThan: BranchCondition = {
    kind: "comparison", left: "{{x}}", operator: "greaterThan", right: "9",
  };
  const lessThanOrEqual: BranchCondition = {
    kind: "comparison", left: "{{x}}", operator: "lessThanOrEqual", right: "10",
  };

  assert.equal(evaluateBranchCondition(greaterThan, resolverFor({"{{x}}": "10"})), true);
  assert.equal(evaluateBranchCondition(greaterThan, resolverFor({"{{x}}": "5"})), false);
  assert.equal(evaluateBranchCondition(lessThanOrEqual, resolverFor({"{{x}}": 10})), true);
});

test("AND-Gruppe trifft nur zu, wenn alle Kinder zutreffen", () => {
  const group: BranchCondition = {
    kind: "group",
    combinator: "and",
    children: [
      {kind: "comparison", left: "{{x}}", operator: "greaterThan", right: "0"},
      {kind: "comparison", left: "{{y}}", operator: "equals", right: "ja"},
    ],
  };

  assert.equal(
    evaluateBranchCondition(group, resolverFor({"{{x}}": 5, "{{y}}": "ja"})),
    true,
  );
  assert.equal(
    evaluateBranchCondition(group, resolverFor({"{{x}}": 5, "{{y}}": "nein"})),
    false,
  );
});

test("OR-Gruppe trifft zu, sobald ein Kind zutrifft", () => {
  const group: BranchCondition = {
    kind: "group",
    combinator: "or",
    children: [
      {kind: "comparison", left: "{{x}}", operator: "equals", right: "1"},
      {kind: "comparison", left: "{{x}}", operator: "equals", right: "2"},
    ],
  };

  assert.equal(evaluateBranchCondition(group, resolverFor({"{{x}}": 2})), true);
  assert.equal(evaluateBranchCondition(group, resolverFor({"{{x}}": 3})), false);
});

test("XOR-Gruppe trifft nur zu, wenn genau ein Kind zutrifft", () => {
  const group: BranchCondition = {
    kind: "group",
    combinator: "xor",
    children: [
      {kind: "comparison", left: "{{a}}", operator: "equals", right: "true"},
      {kind: "comparison", left: "{{b}}", operator: "equals", right: "true"},
    ],
  };

  assert.equal(
    evaluateBranchCondition(group, resolverFor({"{{a}}": true, "{{b}}": false})),
    true,
  );
  assert.equal(
    evaluateBranchCondition(group, resolverFor({"{{a}}": true, "{{b}}": true})),
    false,
  );
  assert.equal(
    evaluateBranchCondition(group, resolverFor({"{{a}}": false, "{{b}}": false})),
    false,
  );
});

test("verschachtelte Gruppen werten rekursiv aus (Klammerung)", () => {
  // (x > 0 AND y == "ja") OR z == "immer"
  const nested: BranchCondition = {
    kind: "group",
    combinator: "or",
    children: [
      {
        kind: "group",
        combinator: "and",
        children: [
          {kind: "comparison", left: "{{x}}", operator: "greaterThan", right: "0"},
          {kind: "comparison", left: "{{y}}", operator: "equals", right: "ja"},
        ],
      },
      {kind: "comparison", left: "{{z}}", operator: "equals", right: "immer"},
    ],
  };

  assert.equal(
    evaluateBranchCondition(nested, resolverFor({"{{x}}": -1, "{{y}}": "ja", "{{z}}": "immer"})),
    true,
  );
  assert.equal(
    evaluateBranchCondition(nested, resolverFor({"{{x}}": -1, "{{y}}": "ja", "{{z}}": "nie"})),
    false,
  );
  assert.equal(
    evaluateBranchCondition(nested, resolverFor({"{{x}}": 1, "{{y}}": "ja", "{{z}}": "nie"})),
    true,
  );
});

test("selectConditionedBranch wählt den ersten zutreffenden Zweig in Listenreihenfolge", () => {
  const branches: ConditionalBranch[] = [
    {
      id: "a", label: "A", nodeIds: [], graph: {nodes: [], edges: []},
      condition: {kind: "comparison", left: "{{x}}", operator: "equals", right: "1"},
    },
    {
      id: "b", label: "B", nodeIds: [], graph: {nodes: [], edges: []},
      condition: {kind: "comparison", left: "{{x}}", operator: "equals", right: "2"},
    },
    {id: "sonst", label: "Sonst", nodeIds: [], graph: {nodes: [], edges: []}},
  ];

  const match = selectConditionedBranch(branches, resolverFor({"{{x}}": 2}));

  assert.equal(match?.branch.id, "b");
  assert.equal(match?.matched, true);
});

test("selectConditionedBranch fällt auf den Sonst-Zweig zurück, wenn nichts zutrifft", () => {
  const branches: ConditionalBranch[] = [
    {
      id: "a", label: "A", nodeIds: [], graph: {nodes: [], edges: []},
      condition: {kind: "comparison", left: "{{x}}", operator: "equals", right: "1"},
    },
    {id: "sonst", label: "Sonst", nodeIds: [], graph: {nodes: [], edges: []}},
  ];

  const match = selectConditionedBranch(branches, resolverFor({"{{x}}": 99}));

  assert.equal(match?.branch.id, "sonst");
  assert.equal(match?.matched, false);
});

test("selectConditionedBranch liefert undefined, wenn nichts zutrifft und kein Sonst-Zweig existiert", () => {
  const branches: ConditionalBranch[] = [
    {
      id: "a", label: "A", nodeIds: [], graph: {nodes: [], edges: []},
      condition: {kind: "comparison", left: "{{x}}", operator: "equals", right: "1"},
    },
  ];

  const match = selectConditionedBranch(branches, resolverFor({"{{x}}": 99}));

  assert.equal(match, undefined);
});
