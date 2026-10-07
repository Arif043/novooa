import assert from "node:assert/strict";
import test from "node:test";
import {taskBuilderOutputFromModelOutput} from "./task-builder-assistant-output.js";

test("keeps valid task builder commands for the interactive plan", () => {
  const output = taskBuilderOutputFromModelOutput({
    answer: "Ich habe einen Vorschlag vorbereitet.",
    commands: [{
      type: "addNode",
      primitive: "readChannelEvent",
      kind: "email",
    }],
    knowledgeCommands: [],
  }, "irrelevant, da bereits strukturiert ausgewertet");

  assert.equal(output.commands.length, 1);
  assert.equal(output.commands[0]?.label, "Baustein „readChannelEvent“ hinzufügen");
  assert.equal(output.commands[0]?.kind, "email");
});

test("drops commands without the data required by the client command factory", () => {
  const output = taskBuilderOutputFromModelOutput({
    answer: "Unvollständiger Vorschlag.",
    commands: [{type: "renameTask"}, {type: "addNode"}],
    knowledgeCommands: [],
  }, "irrelevant, da bereits strukturiert ausgewertet");

  assert.deepEqual(output.commands, []);
});

test("falls back to the raw text when structured output validation failed", () => {
  const output = taskBuilderOutputFromModelOutput(
    undefined,
    "Die Antwort ist frei formulierter Text ohne JSON.",
  );

  assert.deepEqual(output, {
    answer: "Die Antwort ist frei formulierter Text ohne JSON.",
    commands: [],
    knowledgeCommands: [],
  });
});

test("keeps the python script and input template of a script node", () => {
  const output = taskBuilderOutputFromModelOutput({
    answer: "Ich habe ein Script vorbereitet.",
    commands: [{
      type: "addNode",
      primitive: "script",
      script: "output = input.upper()",
      inputTemplate: "{{kundenmail.betreff}}",
    }],
    knowledgeCommands: [],
  }, "irrelevant");

  assert.equal(output.commands[0]?.script, "output = input.upper()");
  assert.equal(output.commands[0]?.inputTemplate, "{{kundenmail.betreff}}");
});
