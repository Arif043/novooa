import assert from "node:assert/strict";
import test from "node:test";
import {ok, err} from "neverthrow";
import {nodeFailures} from "../entities/node-failures.js";
import {createScriptNodeExecutor} from "./script-node-executor.js";
import {succeeded} from "./node-executor-test-support.js";

test("resolves workflow values and delegates execution through the script port", async () => {
  const requests: unknown[] = [];
  const printed: unknown[] = [];
  const executor = createScriptNodeExecutor({
    async execute(request) {
      requests.push(request);
      return ok({
        variables: {count: 2}, printed: "ausgabe", errorOutput: "warnung",
        workflowOutputs: [{name: "gruss", type: "string", value: "Hallo Mila"}],
      });
    },
  }, (value) => printed.push(value));

  const result = succeeded(await executor.execute({
      id: "script-1",
      primitive: "script",
      title: "Script",
      description: "",
      outputs: [{key: "value", name: "script", showOnCanvas: true}],
      config: {
        primitive: "script",
        script: "workflow_output('gruss', 'string', 'Hallo {{name}}')",
        attachments: [],
      },
  } as never, {
    variables: {},
    context: "",
    templateExpressionResolver: {
      resolveText: (value: string) => value.replace(/\{\{name\}\}/g, "Mila"),
    },
  } as never));

  assert.deepEqual(requests, [{
    script: "workflow_output('gruss', 'string', 'Hallo Mila')",
    variables: {},
  }]);
  assert.deepEqual(printed, [{printed: "ausgabe", errorOutput: "warnung"}]);
  assert.deepEqual(result.console, {stdout: "ausgabe", stderr: "warnung"});
  assert.deepEqual(result.outputs, {gruss: {type: "string", value: "Hallo Mila"}});
  assert.deepEqual(result.variables, {count: 2});
});

test("logs what a failing script printed and returns its failure", async () => {
  const printed: unknown[] = [];
  const executor = createScriptNodeExecutor({
    async execute() {
      return err(nodeFailures.scriptFailed("Zeile 2: ValueError: kaputt", {stdout: "Schritt 1\n", stderr: "Warnung\n"}));
    },
  }, (value) => printed.push(value));
  const node = {
    id: "s", primitive: "script", title: "Script", description: "", outputs: [{key: "value", name: "script", showOnCanvas: true}],
    config: {primitive: "script", script: "x", attachments: []},
  } as never;
  const context = {variables: {}, context: "", templateExpressionResolver: {resolveText: (value: string) => value}} as never;

  const failure = (await executor.execute(node, context))._unsafeUnwrapErr();

  assert.equal(failure.code, "scriptFailed");
  assert.match(failure.message, /Zeile 2: ValueError/);
  assert.deepEqual(printed, [{printed: "Schritt 1\n", errorOutput: "Warnung\n"}]);
});

test("a script without workflow_output has no values", async () => {
  const executor = createScriptNodeExecutor({
    async execute() {
      return ok({variables: {gesetzt: 1}, printed: "", errorOutput: ""});
    },
  });
  const node = {
    id: "s", primitive: "script", title: "Script", description: "", outputs: [],
    config: {primitive: "script", script: "gesetzt = 1", attachments: []},
  } as never;
  const context = {variables: {}, context: "", templateExpressionResolver: {resolveText: (value: string) => value}} as never;

  const result = succeeded(await executor.execute(node, context));

  assert.deepEqual(result.outputs, {});
  assert.deepEqual(result.variables, {gesetzt: 1});
});

test("workflow outputs are reachable flat under their name", async () => {
  const executor = createScriptNodeExecutor({
    async execute() {
      return ok({
        variables: {}, printed: "", errorOutput: "",
        workflowOutputs: [{name: "summe", type: "number", value: 42.5}, {name: "kunde", type: "string", value: "Mila"}],
      });
    },
  });
  const node = {
    id: "s", primitive: "script", title: "Script", description: "", outputs: [],
    config: {primitive: "script", script: "workflow_output('summe', 'number', 42.5)", attachments: []},
  } as never;
  const context = {variables: {}, context: "", templateExpressionResolver: {resolveText: (value: string) => value}} as never;

  const result = succeeded(await executor.execute(node, context));

  assert.deepEqual(result.outputs, {
    summe: {type: "number", value: 42.5},
    kunde: {type: "string", value: "Mila"},
  });
});

test("an invalid workflow output fails the node with the script's console output", async () => {
  const executor = createScriptNodeExecutor({
    async execute() {
      return ok({
        variables: {}, printed: "berechnet\n", errorOutput: "",
        workflowOutputs: [{name: "summe", type: "number", value: "42"}],
      });
    },
  });
  const node = {
    id: "s", primitive: "script", title: "Script", description: "", outputs: [],
    config: {primitive: "script", script: "x", attachments: []},
  } as never;
  const context = {variables: {}, context: "", templateExpressionResolver: {resolveText: (value: string) => value}} as never;

  const failure = (await executor.execute(node, context))._unsafeUnwrapErr();

  assert.deepEqual(failure.details, {reason: "wrongValueType", type: "number", name: "summe"});
  assert.deepEqual(failure.console, {stdout: "berechnet\n", stderr: ""});
});
