import assert from "node:assert/strict";
import test from "node:test";
import {XmlPromptRenderer} from "../../../../language_models/domain/prompting/xml-prompt-renderer.js";
import {taskBuilderOrchestratorInstructions} from "./task-builder-orchestrator-prompt.js";

test("the task builder agent introduces itself as noovi", () => {
  const system = new XmlPromptRenderer().render(taskBuilderOrchestratorInstructions.task("?").build()).system ?? "";

  assert.match(system, /You are noovi, novooa's in-app AI agent for the task builder/);
  assert.match(system, /call yourself noovi/);
});
