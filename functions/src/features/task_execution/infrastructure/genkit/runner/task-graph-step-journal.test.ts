import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {type NodeExecutionResult} from "../../../domain/entities/task.js";
import {type TaskRunStepKey, TaskRunStepScope} from "../../../domain/entities/task-run-step-key.js";
import {type TaskRunStepJournal} from "../../../domain/repositories/task-run-step-journal.js";
import {executedNode, type NodeExecutor} from "../../../domain/executors/node-executor.js";
import {forEachNodeExecutor} from "../../../domain/executors/for-each-node-executor.js";
import {NodeExecutorRegistry} from "./node-executor-registry.js";
import {executeTaskGraph} from "./task-graph-runner.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

class InMemoryStepJournal implements TaskRunStepJournal {
  readonly steps = new Map<string, NodeExecutionResult>();
  async find(key: TaskRunStepKey) { return this.steps.get(key.stepPath) ?? null; }
  async record(key: TaskRunStepKey, result: NodeExecutionResult) {
    if (!this.steps.has(key.stepPath)) this.steps.set(key.stepPath, result);
  }
  async clear() { this.steps.clear(); }
}

/** Zählt Ausführungen; `liste` liefert eine Liste, alle anderen ihren aufgelösten Text. */
function countingExecutor(calls: string[]): NodeExecutor {
  return {
    primitive: "stringInput",
    async execute(node, runContext) {
      calls.push(node.id);
      if (node.id === "liste") return executedNode(node, {value: {type: "json", value: [1, 2, 3]}});
      const template = node.config.primitive === "stringInput" ? node.config.value : "";
      return executedNode(node, {value: {type: "string", value: runContext.templateExpressionResolver.resolveText(template)}});
    },
  };
}

function runtimeWith(journal: TaskRunStepJournal, calls: string[]) {
  const executorRegistry = new NodeExecutorRegistry().register(countingExecutor(calls)).register(forEachNodeExecutor);
  return {logger: silentLogger, stepJournal: journal, executorRegistry} as never;
}

const textNode = (id: string, value: string) => ({
  id, primitive: "stringInput", title: id, description: "", outputs: [{key: "value", name: id, showOnCanvas: true}],
  config: {primitive: "stringInput", value},
});
const loopNode = (id: string, body: unknown[]) => ({
  id, primitive: "forEach", title: id, description: "", outputs: [{key: "value", name: id, showOnCanvas: true}],
  config: {primitive: "forEach", itemsTemplate: "{{liste}}", itemsPointer: "", graph: {nodes: body, edges: []}},
});

function taskWith(nodes: unknown[], edges: {from: string; to: string}[], options: {withRun: boolean} = {withRun: true}) {
  const runId = options.withRun ? "run-1" : undefined;
  return {taskDefinition: {id: "task-1", title: "Aufgabe", objective: "", nodes, edges}, context: "", teamId: "team-1", runId} as never;
}

test("a retried run reuses finished steps and executes only the rest", async () => {
  const journal = new InMemoryStepJournal();
  const task = taskWith([textNode("a", "A"), textNode("b", "{{a}}-B")], [{from: "a", to: "b"}]);
  await executeTaskGraph(genkit({}), task, runtimeWith(journal, []));
  journal.steps.delete("b");

  const calls: string[] = [];
  const output = (await executeTaskGraph(genkit({}), task, runtimeWith(journal, calls)))._unsafeUnwrap();

  assert.deepEqual(calls, ["b"]);
  assert.deepEqual(output.nodeResults.map((result) => result.outputs.value), [
    {type: "string", value: "A"}, {type: "string", value: "A-B"},
  ]);
});

test("a retried loop continues with the iterations that did not finish", async () => {
  const journal = new InMemoryStepJournal();
  const task = taskWith([textNode("liste", ""), loopNode("schleife", [textNode("schritt", "x")])], [{from: "liste", to: "schleife"}]);
  await executeTaskGraph(genkit({}), task, runtimeWith(journal, []));
  assert.deepEqual([...journal.steps.keys()].sort(), [
    "liste", "schleife", "schleife:0/schritt", "schleife:1/schritt", "schleife:2/schritt",
  ]);
  ["schleife", "schleife:1/schritt", "schleife:2/schritt"].forEach((path) => journal.steps.delete(path));

  const calls: string[] = [];
  await executeTaskGraph(genkit({}), task, runtimeWith(journal, calls));

  assert.deepEqual(calls, ["schritt", "schritt"]);
});

test("step keys of nested graphs name every enclosing call", () => {
  const outer = TaskRunStepScope.root("team-1", "run-1").forNode("aussen");
  const inner = outer.nested(2).forNode("zweig");

  assert.equal(inner.nested(1).forNode("schritt").stepPath, "aussen:2/zweig:1/schritt");
  assert.equal(inner.runId, "run-1");
  assert.notEqual(outer.nested(0).forNode("schritt").stepPath, outer.nested(1).forNode("schritt").stepPath);
});

test("a step waiting for approval is not journaled", async () => {
  const journal = new InMemoryStepJournal();
  const waitingExecutor: NodeExecutor = {
    primitive: "humanApproval",
    async execute(node) { return {nodeId: node.id, primitive: node.primitive, status: "waitingForApproval", outputs: {}}; },
  };
  const runtime = {logger: silentLogger, stepJournal: journal, executorRegistry: new NodeExecutorRegistry().register(waitingExecutor)} as never;
  const approvalNode = {id: "freigabe", primitive: "humanApproval", title: "freigabe", description: "", outputs: [{key: "value", name: "freigabe", showOnCanvas: true}], config: {primitive: "humanApproval"}};

  const output = (await executeTaskGraph(genkit({}), taskWith([approvalNode], []), runtime))._unsafeUnwrap();

  assert.equal(output.status, "waitingForApproval");
  assert.equal(journal.steps.size, 0);
});

test("a graph without a run journals nothing", async () => {
  const journal = new InMemoryStepJournal();

  await executeTaskGraph(genkit({}), taskWith([textNode("a", "A")], [], {withRun: false}), runtimeWith(journal, []));

  assert.equal(journal.steps.size, 0);
});
