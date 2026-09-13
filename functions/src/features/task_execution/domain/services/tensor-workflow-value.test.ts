import assert from "node:assert/strict";
import test from "node:test";
import {workflowValueForModelOutput} from "./tensor-workflow-value.js";

test("converts a float tensor to nested workflow values", () => {
  const workflowValue = workflowValueForModelOutput({
    type: "tensor",
    dataType: "float32",
    shape: [2, 2, 2],
    values: [1, 2, 3, 4, 5, 6, 7, 8],
  });

  assert.deepEqual(workflowValue, [
    [[1, 2], [3, 4]],
    [[5, 6], [7, 8]],
  ]);
});

test("converts a semantic classification to a workflow value", () => {
  const workflowValue = workflowValueForModelOutput({
    type: "classification",
    classes: [{index: 281, label: "Tabby-Katze", score: 0.76}],
  });

  assert.deepEqual(workflowValue, {
    classes: [{index: 281, label: "Tabby-Katze", score: 0.76}],
  });
});
