import assert from "node:assert/strict";
import test from "node:test";
import {assistantOutputFromModelOutput} from "./knowledge-base-assistant-output.js";

test("normalizes a valid create suggestion without a label", () => {
  const output = assistantOutputFromModelOutput({
    answer: "Ich kann die Notiz anlegen.",
    knowledgeCommands: [{
      type: "createKnowledgeNote",
      title: "LaraEvent",
      content: "Eventdekoration.",
    }],
  }, "irrelevant, da bereits strukturiert ausgewertet");

  assert.deepEqual(output.knowledgeCommands, [{
    type: "createKnowledgeNote",
    label: "Notiz „LaraEvent“ erstellen",
    title: "LaraEvent",
    content: "Eventdekoration.",
  }]);
});

test("discards an update suggestion without a note ID", () => {
  const output = assistantOutputFromModelOutput({
    answer: "Ich bereite die Änderung vor.",
    knowledgeCommands: [{
      type: "updateKnowledgeNote",
      title: "LaraEvent",
      content: "Eventdekoration.",
    }],
  }, "irrelevant, da bereits strukturiert ausgewertet");

  assert.deepEqual(output.knowledgeCommands, []);
});

test("keeps a plain answer when the model does not return structured output", () => {
  const output = assistantOutputFromModelOutput(undefined, "Die Notiz kann erstellt werden.");

  assert.deepEqual(output, {
    answer: "Die Notiz kann erstellt werden.",
    commands: [],
    knowledgeCommands: [],
  });
});

test("keeps several commands of one plan, e.g. atomic notes plus the link back", () => {
  const output = assistantOutputFromModelOutput({
    answer: "Vorschlag",
    knowledgeCommands: [
      {type: "createKnowledgeNote", label: "Fristen anlegen", title: "Fristen", content: "Gehört zu: [[Buchhaltung]]"},
      {type: "createKnowledgeNote", label: "Mahnung anlegen", title: "Mahnung", content: "Siehe [[Fristen]]"},
      {type: "updateKnowledgeNote", label: "Link ergänzen", noteId: "buchhaltung", title: "Buchhaltung", content: "- [[Fristen]]\n- [[Mahnung]]"},
    ],
  }, "");

  assert.deepEqual(output.knowledgeCommands.map((command) => command.type), ["createKnowledgeNote", "createKnowledgeNote", "updateKnowledgeNote"]);
});

