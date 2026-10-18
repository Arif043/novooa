import assert from "node:assert/strict";
import test from "node:test";
import {modelInputFromWorkflowMapping} from "./model-input-from-workflow-mapping.js";

const reader = {readTeamFileContent: async () => { throw new Error("nicht erwartet"); }} as never;

function mapping(dataType: string, shape: (number | "dynamic")[]) {
  return {modelInputName: "eingabe", workflowMapping: "", sourceType: "tensor", dataType, shape} as never;
}

test("builds a string tensor from a nested list of texts", async () => {
  const input = (await modelInputFromWorkflowMapping(mapping("string", ["dynamic", 1]), [["DE"], ["AT"]], "team-1", reader))._unsafeUnwrap();

  assert.equal(input.type, "tensor");
  if (input.type !== "tensor") return;
  assert.deepEqual(input.tensor.shape, [2, 1]);
  assert.deepEqual(JSON.parse(new TextDecoder().decode(input.tensor.bytes)), ["DE", "AT"]);
});

test("numbers for a string tensor and texts for a number tensor are failures", async () => {
  const texts = await modelInputFromWorkflowMapping(mapping("string", [1]), [1], "team-1", reader);
  const numbers = await modelInputFromWorkflowMapping(mapping("float32", [1]), ["a"], "team-1", reader);

  assert.deepEqual(texts._unsafeUnwrapErr().details, {target: "modelInput", expected: "textList", name: "eingabe"});
  assert.deepEqual(numbers._unsafeUnwrapErr().details, {target: "modelInput", expected: "numberList", name: "eingabe"});
});

test("builds a float16 tensor with two bytes per value", async () => {
  const input = (await modelInputFromWorkflowMapping(mapping("float16", [2]), [0.5, -2], "team-1", reader))._unsafeUnwrap();

  assert.equal(input.type, "tensor");
  if (input.type !== "tensor") return;
  const view = new DataView(input.tensor.bytes.buffer, input.tensor.bytes.byteOffset);
  assert.equal(input.tensor.bytes.byteLength, 4);
  assert.deepEqual([view.getFloat16(0, true), view.getFloat16(2, true)], [0.5, -2]);
});
