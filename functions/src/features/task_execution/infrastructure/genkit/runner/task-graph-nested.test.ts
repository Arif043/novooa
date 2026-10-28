import {err, ok} from "neverthrow";
import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {nodeFailures} from "../../../domain/entities/node-failures.js";
import {createConditionalFlowNodeExecutor} from "../../../domain/executors/conditional-node-executor.js";
import {executedNode, type NodeExecutor} from "../../../domain/executors/node-executor.js";
import {forEachNodeExecutor} from "../../../domain/executors/for-each-node-executor.js";
import {NodeExecutorRegistry} from "./node-executor-registry.js";
import {executeTaskGraph} from "./task-graph-runner.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

/** `zahl` liefert 15, `liste` drei Elemente, `kaputt` scheitert in Runde 3; alle anderen „ok“. */
const textExecutor: NodeExecutor = {
  primitive: "stringInput",
  async execute(node, runContext) {
    if (node.id === "zahl") return ok(executedNode(node, {value: {type: "number", value: 15}}));
    if (node.id === "liste") return ok(executedNode(node, {value: {type: "json", value: [1, 2, 3]}}));
    if (node.id === "kaputt" && runContext.scope.iteration?.index === 2) return err(nodeFailures.configurationMissing("kaputt"));
    return ok(executedNode(node, {value: {type: "string", value: `ok ${runContext.scope.iteration?.index ?? "-"}`}}));
  },
};

const runtime = () => ({
  logger: silentLogger,
  executorRegistry: new NodeExecutorRegistry()
    .register(textExecutor).register(forEachNodeExecutor).register(createConditionalFlowNodeExecutor()),
}) as never;

const textNode = (id: string) => ({
  id, primitive: "stringInput", title: id, description: "", outputs: [{key: "value", name: id, showOnCanvas: false}],
  config: {primitive: "stringInput", value: ""},
});
const graphOf = (...ids: string[]) => ({nodes: ids.map(textNode), edges: []});
const task = (nodes: unknown[], edges: {from: string; to: string}[]) => ({
  taskDefinition: {id: "task-1", title: "Aufgabe", objective: "", nodes, edges}, context: "", teamId: "team-1",
}) as never;

const branchTask = task([textNode("zahl"), {
  id: "weiche", primitive: "conditionalFlow", title: "weiche", description: "", outputs: [],
  config: {primitive: "conditionalFlow", valueTemplate: "", choices: ["Groß", "Sonst"], branches: [
    {id: "gross", label: "Groß", nodeIds: [], graph: graphOf("gross-text"),
      condition: {kind: "comparison", left: "{{zahl}}", operator: "greaterThan", right: "10"}},
    {id: "sonst", label: "Sonst", nodeIds: [], graph: graphOf("sonst-text")},
  ]},
}], [{from: "zahl", to: "weiche"}]);

const loopTask = (body: string) => task([textNode("liste"), {
  id: "schleife", primitive: "forEach", title: "schleife", description: "", outputs: [],
  config: {primitive: "forEach", itemsTemplate: "{{liste}}", itemsPointer: "", graph: graphOf(body)},
}], [{from: "liste", to: "schleife"}]);

test("a branch keeps the results of the branch it took, and which one", async () => {
  const output = (await executeTaskGraph(genkit({}), branchTask, runtime()))._unsafeUnwrap();

  const branch = output.nodeResults.find((result) => result.nodeId === "weiche");
  assert.equal(branch?.selectedBranchId, "gross");
  assert.deepEqual(branch?.nested?.map((run) => run.results.map((result) => result.nodeId)), [["gross-text"]]);
});

test("a loop keeps the results of every round with its index", async () => {
  const output = (await executeTaskGraph(genkit({}), loopTask("schritt"), runtime()))._unsafeUnwrap();

  const loop = output.nodeResults.find((result) => result.nodeId === "schleife");
  assert.deepEqual(loop?.nested?.map((run) => [run.iteration, run.results[0]?.outputs.value?.value]), [
    [0, "ok 0"], [1, "ok 1"], [2, "ok 2"],
  ]);
});

test("a loop failing in round 3 keeps the finished rounds and the failed inner node", async () => {
  const failure = (await executeTaskGraph(genkit({}), loopTask("kaputt"), runtime()))._unsafeUnwrapErr();

  const runs = failure.failedNode.nested ?? [];
  assert.deepEqual(runs.map((run) => run.iteration), [0, 1, 2]);
  assert.equal(runs[2]?.failed?.nodeId, "kaputt");
  assert.equal(runs[2]?.results.length, 0);
});
