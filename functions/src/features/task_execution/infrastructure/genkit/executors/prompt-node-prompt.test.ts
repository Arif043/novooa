import assert from "node:assert/strict";
import test from "node:test";
import {XmlPromptRenderer} from "../../../../language_models/domain/prompting/xml-prompt-renderer.js";
import {defaultGenerationOptions} from "../../../../language_models/domain/entities/generation-options.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {promptNodePrompt} from "./prompt-node-prompt.js";
import {type PromptNodeInput} from "./prompt-node-types.js";

const renderer = new XmlPromptRenderer();
const render = (input: PromptNodeInput, workspace?: NodeAttachmentWorkspace) =>
  renderer.render(promptNodePrompt(input, workspace));

test("text prompt: role and answer language in system, the instruction verbatim as task", () => {
  const rendered = render(input({instruction: "Fasse die Mail zusammen."}));

  assert.equal(rendered.user, "<task>\nFasse die Mail zusammen.\n</task>");
  assert.match(rendered.system ?? "", /^<role>\nYou carry out one step of an automated workflow\./);
  assert.match(rendered.system ?? "", /<response_language>\nRespond in the language the task is written in\./);
  assert.doesNotMatch(rendered.system ?? "", /<employee|<attachments|<output_format/);
});

test("employee constraint is its own section next to the base role", () => {
  const rendered = render(input({employee: {id: "e-1", name: "Rezeption", constraint: "Sei freundlich."}}));

  assert.match(rendered.system ?? "", /Act as the employee described in <employee>/);
  assert.match(rendered.system ?? "", /<employee name="Rezeption">\nSei freundlich\.\n<\/employee>/);
});

test("decision and structured prompts get a short output hint, text prompts none", () => {
  const decision = render(input({outputType: "decision", choices: ["ja", "nein"]}));
  const structured = render(input({outputType: "structured"}));

  assert.match(decision.system ?? "", /<output_format>\nAnswer with exactly one of these options: ja, nein\./);
  assert.match(structured.system ?? "", /<output_format>\nFill in every field of the structured output\./);
});

test("attachments name files, directly attached notes and skills", () => {
  const rendered = render(input(), workspace());

  const system = rendered.system ?? "";
  assert.match(system, /<attachments>\nAttached files and knowledge notes are available/);
  assert.match(system, /- files\/rechnung\.pdf \(Rechnung\.pdf\)/);
  assert.match(system, /- knowledge\/leitfaden\.md \(Leitfaden\)/);
  assert.doesNotMatch(system, /verlinkt\.md/, "linked notes are reached through links, not listed");
  assert.match(system, /use_skill tool/);
});

function input(overrides: Partial<PromptNodeInput> = {}): PromptNodeInput {
  return {
    teamId: "team-1", instruction: "Antworte.", outputType: "text", choices: [], structuredFields: [],
    mediaUrls: [], generationOptions: defaultGenerationOptions, ...overrides,
  };
}

function workspace(): NodeAttachmentWorkspace {
  return {
    rootDirectory: "/tmp/ws", skillCount: 1, skillsDirectory: "/tmp/ws/skills",
    files: [{filename: "files/rechnung.pdf", displayName: "Rechnung.pdf"}],
    knowledgeFiles: [
      {filename: "knowledge/leitfaden.md", title: "Leitfaden", isDirectAttachment: true},
      {filename: "knowledge/verlinkt.md", title: "Verlinkt", isDirectAttachment: false},
    ],
    cleanup: () => Promise.resolve(),
  } as never;
}
