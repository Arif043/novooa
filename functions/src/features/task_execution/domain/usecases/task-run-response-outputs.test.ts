import assert from "node:assert/strict";
import test from "node:test";
import {type TaskResumeState} from "../entities/task.js";
import {responseOutputsForTaskRun} from "./task-run-response-outputs.js";

test("maps a dialog submission to typed node outputs", async () => {
  const outputs = await responseOutputsForTaskRun(dialogResumeState(), "", {
    name: "Mila",
    age: 27,
    active: true,
    channel: "E-Mail",
  }, "team-1", {} as never);

  assert.deepEqual(outputs, {
    value: {type: "json", value: {name: "Mila", age: 27, active: true, channel: "E-Mail"}},
    name: {type: "string", value: "Mila"},
    age: {type: "number", value: 27},
    active: {type: "boolean", value: true},
    channel: {type: "string", value: "E-Mail"},
  });
});

test("rejects a dialog submission with an invalid data type", async () => {
  await assert.rejects(
    () => responseOutputsForTaskRun(dialogResumeState(), "", {
      name: "Mila", age: 27.5, active: true, channel: "E-Mail",
    }, "team-1", {} as never),
    /Ungültige Eingabe für "age"/,
  );
});

test("maps a media submission to trusted file outputs", async () => {
  const outputs = await responseOutputsForTaskRun(mediaResumeState(), "", {
    fileId: "image-1",
  }, "team-1", {
    loadTeamFile: async () => ({
      fileId: "image-1",
      versionId: "version-1",
      storagePath: "teams/team-1/files/image-1/versions/version-1/beleg.jpg",
      displayName: "beleg.jpg",
      contentType: "image/jpeg",
      sizeBytes: 42,
    }),
  } as never);

  assert.deepEqual(outputs.value, {
    type: "media",
    value: {
      fileId: "image-1",
      versionId: "version-1",
      displayName: "beleg.jpg",
      contentType: "image/jpeg",
      sizeBytes: 42,
    },
  });
});

function dialogResumeState(): TaskResumeState {
  return {
    nodeResults: [{
      nodeId: "dialog", primitive: "dialogInput", status: "waitingForApproval", outputs: {},
      interaction: {
        kind: "dialogInput",
        instruction: "Bitte ausfüllen.",
        fields: [
          {name: "name", type: "string", options: []},
          {name: "age", type: "integer", options: []},
          {name: "active", type: "boolean", options: []},
          {name: "channel", type: "selection", options: ["E-Mail", "SMS"]},
        ],
      },
    }],
    variables: {}, remainingNodeIds: [], skippedNodeIds: [], waitingNodeId: "dialog",
  };
}

function mediaResumeState(): TaskResumeState {
  return {
    nodeResults: [{
      nodeId: "media",
      primitive: "mediaInput",
      status: "waitingForApproval",
      outputs: {},
      interaction: {
        kind: "mediaInput",
        instruction: "Bitte Bild hinzufügen.",
        documentScanEnabled: false,
      },
    }],
    variables: {}, remainingNodeIds: [], skippedNodeIds: [], waitingNodeId: "media",
  };
}
