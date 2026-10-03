import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {ScriptExecutionError} from "../../../domain/entities/script-execution.js";
import {executeTaskGraph} from "./task-graph-runner.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

const textNode = (id: string, value: string) => ({
  id, primitive: "stringInput", title: id, description: "", outputName: id,
  config: {primitive: "stringInput", value},
});
const scriptNode = (id: string) => ({
  id, primitive: "script", title: id, description: "", outputName: id,
  config: {primitive: "script", script: "x", attachments: []},
});

function runtimeWithScript(execute: () => Promise<never>) {
  return {
    logger: silentLogger,
    scriptExecutorFactory: () => ({execute}),
  } as never;
}

function taskWith(nodes: unknown[], edges: {from: string; to: string}[]) {
  return {taskDefinition: {id: "task-1", title: "Aufgabe", objective: "", nodes, edges}, context: "", teamId: "team-1"} as never;
}

test("a failing node returns a failure with the results of the nodes before it", async () => {
  const ai = genkit({});
  const task = taskWith(
    [textNode("eins", "Hallo"), textNode("zwei", "Welt"), scriptNode("drei")],
    [{from: "eins", to: "zwei"}, {from: "zwei", to: "drei"}],
  );
  const scriptError = new ScriptExecutionError("Zeile 2: ValueError: kaputt", "vorher\n");

  const failure = (await executeTaskGraph(ai, task, runtimeWithScript(async () => { throw scriptError; })))
    ._unsafeUnwrapErr();

  assert.equal(failure.cause, scriptError, "der ursprüngliche Fehler bleibt als Ursache erhalten");
  assert.deepEqual(failure.completedNodeResults.map((result) => [result.nodeId, result.status]), [
    ["eins", "executed"], ["zwei", "executed"],
  ]);
  assert.deepEqual(failure.failedNode, {
    nodeId: "drei", primitive: "script", message: "Zeile 2: ValueError: kaputt",
    console: {stdout: "vorher\n", stderr: ""},
  });
});

test("fails at the first node: nothing before it, but the failed node is named", async () => {
  const ai = genkit({});
  const task = taskWith([scriptNode("eins")], []);

  const failure = (await executeTaskGraph(ai, task, runtimeWithScript(async () => { throw new Error("sofort"); })))
    ._unsafeUnwrapErr();

  assert.deepEqual(failure.completedNodeResults, []);
  assert.equal(failure.failedNode.nodeId, "eins");
  assert.equal(failure.failedNode.message, "sofort");
  assert.equal(failure.failedNode.console, undefined, "ein Fehler ohne Script-Ausgabe hat keine Konsole");
});

test("a run without failure returns its output as a value", async () => {
  const ai = genkit({});
  const task = taskWith([textNode("eins", "Hallo")], []);

  const outputOrFailure = await executeTaskGraph(ai, task, runtimeWithScript(async () => { throw new Error("nicht aufgerufen"); }));

  assert.equal(outputOrFailure.isOk(), true);
});
