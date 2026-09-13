import assert from "node:assert/strict";
import test from "node:test";
import {type PythonJsonProcess} from "./local/local-python-process.js";
import {PythonOnnxModelValidator} from "./python-onnx-model-validator.js";

test("passes model path and contract to the Python validator", async () => {
  const process = new Process(JSON.stringify({valid: true}));
  await new PythonOnnxModelValidator(process).validate(request());
  assert.equal(process.payload?.artifactPath, "model.onnx");
  assert.equal(process.payload?.contract.inputs[0].name, "input");
});

test("rejects an invalid validator response", async () => {
  await assert.rejects(
    new PythonOnnxModelValidator(new Process(JSON.stringify({valid: false}))).validate(request()),
    /kein gültiges Ergebnis/,
  );
});

class Process implements PythonJsonProcess {
  payload: {artifactPath: string; contract: {inputs: Array<{name: string}>}} | undefined;

  constructor(private readonly response: string) {}

  async execute(value: string): Promise<string> {
    this.payload = JSON.parse(value) as typeof this.payload;
    return this.response;
  }
}

function request() {
  return {
    artifactPath: "model.onnx",
    contract: {
      inputs: [{name: "input", source: "tensor" as const, dataType: "uint8" as const, shape: [1], preprocessing: []}],
      outputs: [{name: "output", semantic: "test", dataType: "uint8" as const, shape: [1], postprocessing: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}
