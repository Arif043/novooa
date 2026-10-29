import assert from "node:assert/strict";
import test from "node:test";
import {XmlPromptRenderer} from "../../../language_models/domain/prompting/xml-prompt-renderer.js";
import {knowledgeBaseAssistantInstructions} from "./knowledge-base-assistant-responder.js";

const system = new XmlPromptRenderer().render(knowledgeBaseAssistantInstructions.task("?").build()).system ?? "";

test("instructs the agent to work with our Zettelkasten method", () => {
  assert.match(system, /<reference name="zettelkasten">/);
  assert.match(system, /Atomic: one idea per note/);
  assert.match(system, /No orphans/);
  assert.match(system, /\[\[Title\]\]/);
});

test("lets the agent follow links and cite the notes it used", () => {
  assert.match(system, /follow its links or backlinks/);
  assert.match(system, /cite every note you used as a wiki link/);
});
