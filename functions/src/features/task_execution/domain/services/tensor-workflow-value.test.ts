import assert from "node:assert/strict";
import test from "node:test";
import {workflowValueForTensor} from "./tensor-workflow-value.js";

test("converts a float tensor to nested workflow values", () => {
  const values = new Float32Array([
    1, 2, 3, 4,
    5, 6, 7, 8,
  ]);

  const workflowValue = workflowValueForTensor({
    name: "y",
    semantic: "test.values",
    dataType: "float32",
    shape: [2, 2, 2],
    bytes: new Uint8Array(values.buffer),
  });

  assert.deepEqual(workflowValue, [
    [[1, 2], [3, 4]],
    [[5, 6], [7, 8]],
  ]);
});
