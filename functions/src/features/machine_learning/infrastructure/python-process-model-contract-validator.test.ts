import assert from "node:assert/strict";
import test from "node:test";
import {type ModelContract} from "../domain/entities/model-contract.js";
import {type PythonJsonProcess} from "./local/local-python-process.js";
import {PythonProcessModelContractValidator} from "./python-process-model-contract-validator.js";

test("passes the contract to the Python contract check", async () => {
  const process = new Process(JSON.stringify({status: "ok"}));
  await new PythonProcessModelContractValidator(process).validate(contract());
  assert.equal(process.payload?.contract.inputs[0]?.name, "input");
});

test("rejects an unexpected response of the contract check", async () => {
  await assert.rejects(
    new PythonProcessModelContractValidator(new Process(JSON.stringify({}))).validate(contract()),
    /kein gültiges Ergebnis/,
  );
});

test("forwards the message of a failed contract check", async () => {
  const failing: PythonJsonProcess = {
    execute: async () => {
      throw new Error("Eingang bild: image.resize: Der Parameter width fehlt.");
    },
  };
  await assert.rejects(new PythonProcessModelContractValidator(failing).validate(contract()), /width fehlt/);
});

class Process implements PythonJsonProcess {
  payload: {contract: ModelContract} | undefined;

  constructor(private readonly response: string) {}

  async execute(value: string): Promise<string> {
    this.payload = JSON.parse(value) as typeof this.payload;
    return this.response;
  }
}

function contract(): ModelContract {
  return {
    inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: []}],
    outputs: [{name: "output", semantic: "test", dataType: "uint8", shape: [1], transformations: [], workflowOutput: {name: "value", type: "json", mapping: "$tensor"}}],
  };
}
