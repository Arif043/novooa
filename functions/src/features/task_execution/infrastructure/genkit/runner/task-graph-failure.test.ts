import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {ScriptExecutionError} from "../../../domain/entities/script-execution.js";
import {runFailureDetailsOf} from "../../../domain/services/run-failure-details.js";
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

test("a failing node fails the run and the error carries the results of the nodes before it", async () => {
  const ai = genkit({});
  const task = taskWith(
    [textNode("eins", "Hallo"), textNode("zwei", "Welt"), scriptNode("drei")],
    [{from: "eins", to: "zwei"}, {from: "zwei", to: "drei"}],
  );
  const failure = new ScriptExecutionError("Zeile 2: ValueError: kaputt", "vorher\n");

  const error = await executeTaskGraph(ai, task, runtimeWithScript(async () => { throw failure; })).then(
    () => undefined, (caught: unknown) => caught,
  );

  assert.equal(error, failure, "der Fehler bleibt derselbe: gleiche Meldung, gleicher Typ");
  const details = runFailureDetailsOf(error);
  assert.deepEqual(details.completedNodeResults.map((result) => [result.nodeId, result.status]), [
    ["eins", "executed"], ["zwei", "executed"],
  ]);
  assert.deepEqual(details.failedNode, {
    nodeId: "drei", primitive: "script", message: "Zeile 2: ValueError: kaputt",
    console: {stdout: "vorher\n", stderr: ""},
  });
});

test("fails at the first node: nothing before it, but the failed node is named", async () => {
  const ai = genkit({});
  const task = taskWith([scriptNode("eins")], []);

  const error = await executeTaskGraph(ai, task, runtimeWithScript(async () => { throw new Error("sofort"); })).then(
    () => undefined, (caught: unknown) => caught,
  );

  assert.match((error as Error).message, /sofort/);
  const details = runFailureDetailsOf(error);
  assert.deepEqual(details.completedNodeResults, []);
  assert.equal(details.failedNode?.nodeId, "eins");
  assert.equal(details.failedNode?.console, undefined, "ein Fehler ohne Script-Ausgabe hat keine Konsole");
});

test("non-object failures do not break the run handling", () => {
  assert.deepEqual(runFailureDetailsOf("Text"), {completedNodeResults: []});
  assert.deepEqual(runFailureDetailsOf(undefined), {completedNodeResults: []});
});
