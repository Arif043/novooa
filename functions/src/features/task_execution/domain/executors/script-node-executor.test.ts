import assert from "node:assert/strict";
import test from "node:test";
import {ScriptExecutionError} from "../entities/script-execution.js";
import {createScriptNodeExecutor} from "./script-node-executor.js";

test("resolves workflow values and delegates execution through the script port", async () => {
  const requests: unknown[] = [];
  const printed: string[] = [];
  const executor = createScriptNodeExecutor({
    async execute(request) {
      requests.push(request);
      return {output: "fertig", variables: {count: 2}, printed: "ausgabe"};
    },
  }, (value: string) => printed.push(value));

  const result = await executor.execute({
      id: "script-1",
      primitive: "script",
      title: "Script",
      description: "",
      outputName: "script",
      config: {
        primitive: "script",
        script: "output = '{{name}}'",
        inputTemplate: "Hallo {{name}}",
        attachments: [],
      },
  } as never, {
    variables: {},
    context: "",
    templateExpressionResolver: {
      resolveText: (value: string) => value.replace(/\{\{name\}\}/g, "Mila"),
    },
  } as never);

  assert.deepEqual(requests, [{
    input: "Hallo Mila",
    script: "output = 'Mila'",
    variables: {},
  }]);
  assert.deepEqual(printed, ["ausgabe"]);
  assert.deepEqual(result.outputs.value, {type: "string", value: "fertig"});
  assert.deepEqual(result.variables, {count: 2});
});

test("logs what a failing script printed before the error is rethrown", async () => {
  const printed: string[] = [];
  const executor = createScriptNodeExecutor({
    async execute() { throw new ScriptExecutionError("Zeile 2: ValueError: kaputt", "Schritt 1\n"); },
  }, (value: string) => printed.push(value));
  const node = {
    id: "s", primitive: "script", title: "Script", description: "", outputName: "script",
    config: {primitive: "script", script: "x", attachments: []},
  } as never;
  const context = {variables: {}, context: "", templateExpressionResolver: {resolveText: (value: string) => value}} as never;

  await assert.rejects(executor.execute(node, context), /Zeile 2: ValueError/);
  assert.deepEqual(printed, ["Schritt 1\n"]);
});
