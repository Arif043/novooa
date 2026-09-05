import assert from "node:assert/strict";
import test from "node:test";
import {dialogInputNodeExecutor} from "./dialog-input-node-executor.js";

test("pauses a run and preserves the dialog definition", async () => {
  const result = await dialogInputNodeExecutor.execute({
    node: {
      id: "dialog", primitive: "dialogInput", config: {
        primitive: "dialogInput", instruction: "Hallo {{name}}", fields: [
          {name: "age", type: "integer", options: []},
        ],
      },
    },
  } as never, {
    resolveTemplates: (value: string) => value.replace("{{name}}", "Mila"),
  } as never);

  assert.equal(result.status, "waitingForApproval");
  assert.equal(result.message, "Hallo Mila");
  assert.deepEqual(result.interaction, {
    kind: "dialogInput",
    instruction: "Hallo Mila",
    fields: [
    {name: "age", type: "integer", options: []},
    ],
  });
});
