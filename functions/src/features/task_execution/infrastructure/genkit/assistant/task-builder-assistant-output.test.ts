import assert from "node:assert/strict";
import test from "node:test";
import {taskBuilderOutputFromText} from "./task-builder-assistant-output.js";

test("keeps valid task builder commands for the interactive plan", () => {
  const output = taskBuilderOutputFromText(JSON.stringify({
    answer: "Ich habe einen Vorschlag vorbereitet.",
    commands: [{
      type: "addNode",
      primitive: "readChannelEvent",
      kind: "email",
    }],
    knowledgeCommands: [],
  }));

  assert.equal(output.commands.length, 1);
  assert.equal(output.commands[0]?.label, "Baustein „readChannelEvent“ hinzufügen");
  assert.equal(output.commands[0]?.kind, "email");
});

test("drops commands without the data required by the client command factory", () => {
  const output = taskBuilderOutputFromText(JSON.stringify({
    answer: "Unvollständiger Vorschlag.",
    commands: [{type: "renameTask"}, {type: "addNode"}],
    knowledgeCommands: [],
  }));

  assert.deepEqual(output.commands, []);
});
