import assert from "node:assert/strict";
import test from "node:test";
import {assistantOutputFromText} from "./knowledge-base-assistant-output.js";

test("normalizes a valid create suggestion without a label", () => {
  const output = assistantOutputFromText(JSON.stringify({
    answer: "Ich kann die Notiz anlegen.",
    knowledgeCommands: [{
      type: "createKnowledgeNote",
      title: "LaraEvent",
      content: "Eventdekoration.",
    }],
  }));

  assert.deepEqual(output.knowledgeCommands, [{
    type: "createKnowledgeNote",
    label: "Notiz „LaraEvent“ erstellen",
    title: "LaraEvent",
    content: "Eventdekoration.",
  }]);
});

test("discards an update suggestion without a note ID", () => {
  const output = assistantOutputFromText(JSON.stringify({
    answer: "Ich bereite die Änderung vor.",
    knowledgeCommands: [{
      type: "updateKnowledgeNote",
      title: "LaraEvent",
      content: "Eventdekoration.",
    }],
  }));

  assert.deepEqual(output.knowledgeCommands, []);
});

test("keeps a plain answer when the model does not return JSON", () => {
  const output = assistantOutputFromText("Die Notiz kann erstellt werden.");

  assert.deepEqual(output, {
    answer: "Die Notiz kann erstellt werden.",
    commands: [],
    knowledgeCommands: [],
  });
});
