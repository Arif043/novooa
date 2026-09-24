import assert from "node:assert/strict";
import test from "node:test";
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
