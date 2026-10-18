import assert from "node:assert/strict";
import test from "node:test";
import {ok, err} from "neverthrow";
import {nodeFailures} from "../entities/node-failures.js";
import {type WorkflowInputValue} from "../entities/workflow-value.js";
import {createScriptNodeExecutor} from "./script-node-executor.js";
import {succeeded} from "./node-executor-test-support.js";

function scriptNode(script: string) {
  return {
    id: "s", primitive: "script", title: "Script", description: "", outputs: [],
    config: {primitive: "script", script, attachments: []},
  } as never;
}

function contextWith(values: Record<string, WorkflowInputValue> = {}) {
  return {templateExpressionResolver: {typedValueAt: (path: string) => values[path]}} as never;
}

test("sends the script unchanged with the typed values it reads via workflow_input", async () => {
  const requests: unknown[] = [];
  const printed: unknown[] = [];
  const executor = createScriptNodeExecutor({
    async execute(request) {
      requests.push(request);
      return ok({
        printed: "ausgabe", errorOutput: "warnung",
        workflowOutputs: [{name: "gruss", type: "string", value: "Hallo Mila"}],
      });
    },
  }, (value) => printed.push(value));
  const script = [
    "name = workflow_input(\"kunde.name\")",
    "faellig = workflow_input('faellig')",
    "fehlt = workflow_input(\"gibt_es_nicht\")",
    "text = f\"{{wörtlich}}\"",
    "workflow_output('gruss', 'string', 'Hallo ' + name)",
  ].join("\n");

  const result = succeeded(await executor.execute(scriptNode(script), contextWith({
    "kunde.name": {type: "json", value: "Mila"},
    "faellig": {type: "datetime", value: "2026-10-18T09:30:00"},
  })));

  assert.deepEqual(requests, [{
    script,
    inputs: {
      "kunde.name": {type: "json", value: "Mila"},
      "faellig": {type: "datetime", value: "2026-10-18T09:30:00"},
    },
    packages: [],
  }]);
  assert.deepEqual(printed, [{printed: "ausgabe", errorOutput: "warnung"}]);
  assert.deepEqual(result.console, {stdout: "ausgabe", stderr: "warnung"});
  assert.deepEqual(result.outputs, {gruss: {type: "string", value: "Hallo Mila"}});
});

test("sends the normalized package list of the block", async () => {
  const requests: Array<{packages: string[]}> = [];
  const executor = createScriptNodeExecutor({
    async execute(request) {
      requests.push(request);
      return ok({printed: "", errorOutput: ""});
    },
  });
  const node = {
    id: "s", primitive: "script", title: "Script", description: "", outputs: [],
    config: {primitive: "script", script: "import six", packages: ["Six", "pandas == 2.2.3"], attachments: []},
  } as never;

  await executor.execute(node, contextWith());

  assert.deepEqual(requests[0].packages, ["pandas==2.2.3", "six"]);
});

test("logs what a failing script printed and returns its failure", async () => {
  const printed: unknown[] = [];
  const executor = createScriptNodeExecutor({
    async execute() {
      return err(nodeFailures.scriptFailed("Zeile 2: ValueError: kaputt", {stdout: "Schritt 1\n", stderr: "Warnung\n"}));
    },
  }, (value) => printed.push(value));

  const failure = (await executor.execute(scriptNode("x"), contextWith()))._unsafeUnwrapErr();

  assert.equal(failure.code, "scriptFailed");
  assert.match(failure.message, /Zeile 2: ValueError/);
  assert.deepEqual(printed, [{printed: "Schritt 1\n", errorOutput: "Warnung\n"}]);
});

test("a script without workflow_output has no values", async () => {
  const executor = createScriptNodeExecutor({
    async execute() {
      return ok({printed: "", errorOutput: ""});
    },
  });

  const result = succeeded(await executor.execute(scriptNode("gesetzt = 1"), contextWith()));

  assert.deepEqual(result.outputs, {});
});

test("workflow outputs are reachable flat under their name", async () => {
  const executor = createScriptNodeExecutor({
    async execute() {
      return ok({
        printed: "", errorOutput: "",
        workflowOutputs: [{name: "summe", type: "number", value: 42.5}, {name: "kunde", type: "string", value: "Mila"}],
      });
    },
  });

  const result = succeeded(await executor.execute(scriptNode("workflow_output('summe', 'number', 42.5)"), contextWith()));

  assert.deepEqual(result.outputs, {
    summe: {type: "number", value: 42.5},
    kunde: {type: "string", value: "Mila"},
  });
});

test("an invalid workflow output fails the node with the script's console output", async () => {
  const executor = createScriptNodeExecutor({
    async execute() {
      return ok({
        printed: "berechnet\n", errorOutput: "",
        workflowOutputs: [{name: "summe", type: "number", value: "42"}],
      });
    },
  });

  const failure = (await executor.execute(scriptNode("x"), contextWith()))._unsafeUnwrapErr();

  assert.deepEqual(failure.details, {reason: "wrongValueType", type: "number", name: "summe"});
  assert.deepEqual(failure.console, {stdout: "berechnet\n", stderr: ""});
});
