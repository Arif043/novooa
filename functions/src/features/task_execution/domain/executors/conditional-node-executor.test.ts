import assert from "node:assert/strict";
import test from "node:test";
import {createConditionalFlowNodeExecutor} from "./conditional-node-executor.js";
import {type TaskRunContext} from "./node-executor.js";
import {type ConditionalBranch} from "../entities/task.js";
import {NodeFailedError} from "../entities/node-execution-failure.js";

// Deckt die neue Weiche in `conditional-node-executor.ts` ab: Trägt
// irgendein Branch ein `condition`, wird ausschließlich über
// `selectConditionedBranch` entschieden; ansonsten bleibt der bestehende
// Label-Matching-Pfad (`executeConditionalFlow`) exakt unverändert —
// Regressionsschutz für Entscheidungs-Prompt-getriebene und alte
// Bausteine, die niemals ein `condition` besitzen.

test("wählt den ersten bedingten Zweig, dessen Ausdruck zutrifft", async () => {
  const branches: ConditionalBranch[] = [
    {
      id: "gross",
      label: "Groß",
      nodeIds: [],
      graph: {nodes: [], edges: []},
      condition: {kind: "comparison", left: "{{x}}", operator: "greaterThan", right: "10"},
    },
    {id: "sonst", label: "Sonst", nodeIds: [], graph: {nodes: [], edges: []}},
  ];
  const executor = createConditionalFlowNodeExecutor();

  const result = await executor.execute(
    conditionalNode(branches),
    runContext({"{{x}}": 15}),
  );

  assert.equal(result.selectedBranchId, "gross");
});

test("fällt auf den Sonst-Zweig zurück, wenn keine Bedingung zutrifft", async () => {
  const branches: ConditionalBranch[] = [
    {
      id: "gross",
      label: "Groß",
      nodeIds: [],
      graph: {nodes: [], edges: []},
      condition: {kind: "comparison", left: "{{x}}", operator: "greaterThan", right: "10"},
    },
    {id: "sonst", label: "Sonst", nodeIds: [], graph: {nodes: [], edges: []}},
  ];
  const executor = createConditionalFlowNodeExecutor();

  const result = await executor.execute(
    conditionalNode(branches),
    runContext({"{{x}}": 5}),
  );

  assert.equal(result.selectedBranchId, "sonst");
});

test(
  "verhält sich für Knoten ganz ohne `condition` exakt wie zuvor "
  + "(Label-Matching gegen den aufgelösten valueTemplate)",
  async () => {
    const branches: ConditionalBranch[] = [
      {id: "ja", label: "Ja", nodeIds: [], graph: {nodes: [], edges: []}},
      {id: "nein", label: "Nein", nodeIds: [], graph: {nodes: [], edges: []}},
    ];
    const executor = createConditionalFlowNodeExecutor();

    const result = await executor.execute(
      conditionalNode(branches, "{{entscheidung}}"),
      runContext({"{{entscheidung}}": "Nein"}),
    );

    assert.equal(result.selectedBranchId, "nein");
  },
);

test("ein Zweig ohne Bausteine liefert seinen Namen als Wert", async () => {
  const branches: ConditionalBranch[] = [
    {id: "sonst", label: "Sonst", nodeIds: [], graph: {nodes: [], edges: []}},
    {
      id: "gross", label: "Groß", nodeIds: [], graph: {nodes: [], edges: []},
      condition: {kind: "comparison", left: "{{x}}", operator: "greaterThan", right: "10"},
    },
  ];

  const result = await createConditionalFlowNodeExecutor().execute(
    conditionalNode(branches), runContext({"{{x}}": 15}),
  );

  assert.deepEqual(result.outputs, {value: {type: "string", value: "Groß"}});
});

test("ein unpassender Wert lässt den Baustein mit Code und Feldern scheitern", async () => {
  const branches: ConditionalBranch[] = [{
    id: "alt", label: "Alt", nodeIds: [], graph: {nodes: [], edges: []},
    condition: {kind: "comparison", left: "{{datum}}", operator: "before", right: "2026-01-01"},
  }];

  await assert.rejects(
    createConditionalFlowNodeExecutor().execute(conditionalNode(branches), runContext({"{{datum}}": "29.09.2026"})),
    (error: unknown) => {
      assert.ok(error instanceof NodeFailedError);
      assert.equal(error.reason.code, "conditionOperandMismatch");
      assert.deepEqual(error.reason.details, {operator: "before", expected: "date", received: "29.09.2026"});
      return true;
    },
  );
});

function conditionalNode(branches: ConditionalBranch[], valueTemplate = "") {
  return {
    id: "decision",
    primitive: "conditionalFlow" as const,
    title: "Bedingter Ablauf",
    description: "",
    outputs: [],
    config: {
      primitive: "conditionalFlow" as const,
      valueTemplate,
      choices: branches.map((branch) => branch.label),
      branches,
    },
  };
}

function runContext(templateValues: Record<string, unknown> = {}): TaskRunContext {
  return {
    context: "",
    currentGraph: {nodes: [], edges: []},
    templateExpressionResolver: {
      resolveValue: (value: string) => templateValues[value] ?? value,
      resolveText: (value: string) =>
        typeof templateValues[value] === "string"
          ? (templateValues[value])
          : value,
    },
    runGraph: async () => [],
  } as unknown as TaskRunContext;
}
