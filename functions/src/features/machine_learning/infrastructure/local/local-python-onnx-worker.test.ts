import assert from "node:assert/strict";
import {mkdtemp, rm, writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import path from "node:path";
import test from "node:test";
import {LocalPythonOnnxWorker} from "./local-python-onnx-worker.js";

test("exchanges binary tensors with an injected local Python worker", async () => {
  const directory = await mkdtemp(path.join(tmpdir(), "novooa-onnx-worker-"));
  try {
    const scriptPath = await workerScriptIn(directory);
    const worker = new LocalPythonOnnxWorker({
      pythonExecutable: "python3",
      workerScriptPath: scriptPath,
    });
    const outputs = await worker.execute({
      artifact: Uint8Array.from([1]),
      inputs: [{name: "input", dataType: "uint8", shape: [1], bytes: Uint8Array.from([12])}],
      outputNames: ["output"],
    });
    assert.equal(outputs[0].name, "output");
    assert.deepEqual([...outputs[0].bytes], [12]);
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
});

async function workerScriptIn(directory: string): Promise<string> {
  const scriptPath = path.join(directory, "worker.py");
  await writeFile(scriptPath, workerSource, "utf8");
  return scriptPath;
}

const workerSource = `
import json
import sys

payload = json.loads(sys.stdin.read())
sys.stdout.write(json.dumps({
  "outputs": [{
    "name": payload["outputNames"][0],
    "dataType": payload["inputs"][0]["dataType"],
    "shape": payload["inputs"][0]["shape"],
    "dataBase64": payload["inputs"][0]["dataBase64"],
  }],
}))
`;
