import {err, ok} from "neverthrow";
import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {type NodeExecutionResult} from "../../../domain/entities/task.js";
import {type TaskRunStepKey} from "../../../domain/entities/task-run-step-key.js";
import {nodeFailures} from "../../../domain/entities/node-failures.js";
import {executedNode, type NodeExecutor} from "../../../domain/executors/node-executor.js";
import {forEachNodeExecutor} from "../../../domain/executors/for-each-node-executor.js";
import {type TaskRunStepJournal} from "../../../domain/repositories/task-run-step-journal.js";
import {NodeExecutorRegistry} from "./node-executor-registry.js";
import {executeTaskGraph} from "./task-graph-runner.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

class InMemoryStepJournal implements TaskRunStepJournal {
  readonly steps = new Map<string, NodeExecutionResult>();
  async find(key: TaskRunStepKey) { return this.steps.get(key.stepPath) ?? null; }
  async record(key: TaskRunStepKey, result: NodeExecutionResult) { this.steps.set(key.stepPath, result); }
  async clear() { this.steps.clear(); }
}

/** `liste` liefert drei Elemente; `melder` benachrichtigt das Team und scheitert bei `failAt`. */
function executor(options: {failAt?: number} = {}): NodeExecutor {
  return {
    primitive: "stringInput",
    async execute(node, runContext) {
      if (node.id === "liste") return ok(executedNode(node, {value: {type: "json", value: [1, 2, 3]}}));
      const round = runContext.scope.iteration?.index;
      if (round !== undefined && round === options.failAt) return err(nodeFailures.configurationMissing("melder"));
      await runContext.teamNotificationSender.sendToTeam(runContext.teamId, {title: `Runde ${round ?? "-"}`, body: "", data: {}});
      return ok(executedNode(node, {value: {type: "string", value: "ok"}}));
    },
  };
}

function runtime(sent: string[], options: {failAt?: number; journal?: TaskRunStepJournal} = {}) {
  const executorRegistry = new NodeExecutorRegistry().register(executor(options)).register(forEachNodeExecutor);
  return {
    logger: silentLogger, executorRegistry, stepJournal: options.journal,
    teamNotificationSender: {sendToTeam: async (_team: string, notification: {title: string}) => {
      sent.push(notification.title);
    }},
  } as never;
}

const textNode = (id: string) => ({
  id, primitive: "stringInput", title: id, description: "", outputs: [{key: "value", name: id, showOnCanvas: true}],
  config: {primitive: "stringInput", value: ""},
});
const loopTask = {
  taskDefinition: {
    id: "task-1", title: "Aufgabe", objective: "", edges: [{from: "liste", to: "schleife"}],
    nodes: [textNode("liste"), {
      id: "schleife", primitive: "forEach", title: "schleife", description: "", outputs: [],
      config: {primitive: "forEach", itemsTemplate: "{{liste}}", itemsPointer: "", graph: {nodes: [textNode("melder")], edges: []}},
    }],
  },
  context: "", teamId: "team-1", runId: "run-1",
} as never;

const rounds = (effects: readonly {sourceNodeId: string; iteration?: number}[] | undefined) =>
  (effects ?? []).map((effect) => `${effect.sourceNodeId}:${effect.iteration}`);

test("effects of a loop body arrive at the loop, naming the inner node and its round", async () => {
  const output = (await executeTaskGraph(genkit({}), loopTask, runtime([])))._unsafeUnwrap();

  const loop = output.nodeResults.find((result) => result.nodeId === "schleife");
  assert.deepEqual(rounds(loop?.effects), ["melder:0", "melder:1", "melder:2"]);
  assert.equal(output.nodeResults.find((result) => result.nodeId === "liste")?.effects, undefined);
});

test("a loop that fails in round 3 keeps the effects of the first two rounds", async () => {
  const failure = (await executeTaskGraph(genkit({}), loopTask, runtime([], {failAt: 2})))._unsafeUnwrapErr();

  assert.equal(failure.failedNode.nodeId, "schleife");
  assert.deepEqual(rounds(failure.failedNode.effects), ["melder:0", "melder:1"]);
});

test("a retried loop neither repeats nor loses effects of finished rounds", async () => {
  const journal = new InMemoryStepJournal();
  await executeTaskGraph(genkit({}), loopTask, runtime([], {journal, failAt: 2}));

  const sent: string[] = [];
  const output = (await executeTaskGraph(genkit({}), loopTask, runtime(sent, {journal})))._unsafeUnwrap();

  assert.deepEqual(sent, ["Runde 2"], "only the missing round notifies again");
  const loop = output.nodeResults.find((result) => result.nodeId === "schleife");
  assert.deepEqual(rounds(loop?.effects), ["melder:0", "melder:1", "melder:2"]);
});
