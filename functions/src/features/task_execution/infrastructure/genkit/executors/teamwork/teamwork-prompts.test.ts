import assert from "node:assert/strict";
import test from "node:test";
import {XmlPromptRenderer} from "../../../../../language_models/domain/prompting/xml-prompt-renderer.js";
import {memberSystemPrompt, orchestratorPrompt} from "./teamwork-prompts.js";
import {reviewPrompt} from "./teamwork-review-prompts.js";
import {teamworkResultFields} from "./teamwork-output-schema.js";

const renderer = new XmlPromptRenderer();

test("the orchestrator gets team, working folder, attachments and images in its system part and the instruction verbatim", () => {
  const rendered = renderer.render(orchestratorPrompt({
    members: [{toolName: "delegate_to_recherche", employeeId: "e1", employeeName: "Recherche", responsibility: "Findet Fakten"}],
    fields: [{name: "bericht", description: "", type: "file", fileFormat: "markdown"}],
    instruction: "Wie groß ist X?", mediaUrls: ["data:image/png;base64,AAA"], imagePaths: ["images/bild-1.png"],
    workspace: {rootDirectory: "/ws", files: [], knowledgeFiles: [], skillCount: 0, cleanup: () => Promise.resolve()},
  }));

  const system = rendered.system ?? "";
  assert.match(system, /<reference name="team">\n- delegate_to_recherche: Recherche – Findet Fakten\n<\/reference>/);
  assert.match(system, /<reference name="workspace">\nWorking folder/);
  assert.match(system, /<attachments>[\s\S]*images\/bild-1\.png[\s\S]*<\/attachments>/);
  assert.match(system, /<output_format>[\s\S]*- bericht: Markdown \(\.md\)/);
  assert.match(system, /Write assignments in the language of the task\./);
  assert.equal(rendered.user, "<task>\nWie groß ist X?\n</task>");
});

test("a member's system part names its constraint only when there is one", () => {
  const withConstraint = memberSystemPrompt({id: "e1", name: "Recherche", constraint: "Du recherchierst gründlich."}) ?? "";
  const withoutConstraint = memberSystemPrompt({id: "e2", name: "Leer", constraint: " "}) ?? "";

  assert.match(withConstraint, /<employee name="Recherche">\nDu recherchierst gründlich\.\n<\/employee>/);
  assert.match(withConstraint, /Act as the employee described in <employee>/);
  assert.doesNotMatch(withoutConstraint, /<employee/);
});

test("the review sees instruction, fields and result as separate sections", () => {
  const rendered = renderer.render(reviewPrompt("Wie groß ist X?", [
    {name: "groesse", description: "In Metern", type: "number"},
  ], {groesse: 42}));

  assert.match(rendered.user, /^<task>\nWie groß ist X\?\n<\/task>/);
  assert.match(rendered.user, /<context name="result_fields">\n- groesse \(number\): In Metern\n<\/context>/);
  assert.match(rendered.user, /<context name="result">\n\{\n {2}"groesse": 42\n\}\n<\/context>/);
});

test("file fields of the result become path fields with an English hint", () => {
  const [file, value] = teamworkResultFields([
    {name: "bericht", description: "Der Bericht.", type: "file", fileFormat: "markdown"},
    {name: "anzahl", description: "", type: "number"},
  ]);

  assert.deepEqual(file, {name: "bericht", type: "string", description: "Der Bericht. Path of the result file under shared/, e.g. shared/bericht.md."});
  assert.deepEqual(value, {name: "anzahl", type: "number", description: ""});
});
