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

const storedImage = {
  fileId: "image-1",
  versionId: "version-1",
  storagePath: "teams/team-1/files/image-1/versions/version-1/beleg.jpg",
  displayName: "beleg.jpg",
  contentType: "image/jpeg",
  sizeBytes: 42,
};
const imageReference = {
  fileId: "image-1", versionId: "version-1", displayName: "beleg.jpg", contentType: "image/jpeg", sizeBytes: 42,
};

function filesReturning(file: Record<string, unknown>) {
  const requested: string[] = [];
  return {requested, store: {loadTeamFile: async (_teamId: string, fileId: string) => {
    requested.push(fileId);
    return file;
  }} as never};
}

test("ein Bildfeld wird zur Referenz auf die Team-Datei, neben den übrigen Feldern", async () => {
  const files = filesReturning(storedImage);

  const outputs = await responseOutputsForTaskRun(imageResumeState(), "", {betrag: 12.5, beleg: "image-1"}, "team-1", files.store);

  assert.deepEqual(files.requested, ["image-1"]);
  assert.deepEqual(outputs.beleg, {type: "media", value: imageReference});
  assert.deepEqual(outputs.betrag, {type: "number", value: 12.5});
  assert.deepEqual(outputs.value, {type: "json", value: {betrag: 12.5, beleg: imageReference}});
});

test("ein Bildfeld ohne Datei wird abgelehnt", async () => {
  await assert.rejects(
    () => responseOutputsForTaskRun(imageResumeState(), "", {betrag: 1}, "team-1", filesReturning(storedImage).store),
    /Ungültige Eingabe für "beleg"/,
  );
});

test("eine Datei, die kein Bild ist, wird abgelehnt", async () => {
  const pdf = {...storedImage, contentType: "application/pdf"};

  await assert.rejects(
    () => responseOutputsForTaskRun(imageResumeState(), "", {betrag: 1, beleg: "image-1"}, "team-1", filesReturning(pdf).store),
    /kein Bild/,
  );
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
    remainingNodeIds: [], skippedNodeIds: [], waitingNodeId: "dialog",
  };
}

function imageResumeState(): TaskResumeState {
  return {
    nodeResults: [{
      nodeId: "beleg-formular", primitive: "dialogInput", status: "waitingForApproval", outputs: {},
      interaction: {
        kind: "dialogInput",
        instruction: "Beleg fotografieren und Betrag angeben.",
        fields: [
          {name: "betrag", type: "decimal", options: []},
          {name: "beleg", type: "image", options: []},
        ],
      },
    }],
    remainingNodeIds: [], skippedNodeIds: [], waitingNodeId: "beleg-formular",
  };
}
