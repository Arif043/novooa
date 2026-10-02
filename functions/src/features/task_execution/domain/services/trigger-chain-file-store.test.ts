import assert from "node:assert/strict";
import test from "node:test";
import {triggerChainFrom} from "../../../scheduling/domain/entities/trigger-chain.js";
import {TriggerChainTeamFileStore} from "./trigger-chain-file-store.js";

function recordingStore(written: Array<Record<string, unknown>>) {
  return {
    writeTeamFile: async (input: Record<string, unknown>) => {
      written.push(input);
      return {} as never;
    },
    loadTeamFile: async () => ({}) as never,
    readTextFile: async () => "inhalt",
  };
}

const writeInput = {
  teamId: "t", content: "x", fileName: "a.txt", contentType: "text/plain", targetFileId: null,
};

test("hängt die Ursachenkette des Laufs an jeden Schreibvorgang", async () => {
  const written: Array<Record<string, unknown>> = [];
  const store = new TriggerChainTeamFileStore(recordingStore(written), ["a", "b"]);

  await store.writeTeamFile(writeInput);

  assert.deepEqual(written[0].triggerChain, ["a", "b"]);
});

test("lässt Schreibvorgänge ohne Kette unverändert", async () => {
  const written: Array<Record<string, unknown>> = [];
  const store = new TriggerChainTeamFileStore(recordingStore(written), []);

  await store.writeTeamFile(writeInput);

  assert.equal("triggerChain" in written[0], false);
  assert.equal(await store.readTextFile("t", {} as never), "inhalt");
});

test("liest die Kette defensiv aus dem Lauf-Input", () => {
  assert.deepEqual(triggerChainFrom({triggerChain: ["a", 3, "b"]}), ["a", "b"]);
  assert.deepEqual(triggerChainFrom({triggerChain: "a"}), []);
  assert.deepEqual(triggerChainFrom(undefined), []);
});
