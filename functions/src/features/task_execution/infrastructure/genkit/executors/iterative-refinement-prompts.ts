import {type IterativeRefinementRequest} from "../../../domain/entities/iterative-refinement-execution.js";
import {type LlmPrompt} from "../../../../language_models/domain/prompting/llm-prompt.js";
import {PromptBuilder} from "../../../../language_models/domain/prompting/prompt-builder.js";
import {sameAsTask} from "../../../../language_models/domain/prompting/response-language.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {attachmentsSectionFor, roleWithEmployee} from "./workflow-prompt-sections.js";

const reviewerRole = [
  "You review a draft in an automated workflow.",
  "<task> contains the review criteria; <context name=\"objective\"> the overall goal; <context name=\"draft\"> the draft to review.",
  "Judge strictly against the criteria.",
].join(" ");

const optimizerRole = [
  "You revise a draft in an automated workflow.",
  "<task> contains the revision instructions; apply the feedback in <context name=\"feedback\"> to <context name=\"current_draft\">.",
  "Return only the revised draft, without introduction or closing remarks.",
].join(" ");

/** Gemeinsamer Kern: Rolle, Mitarbeiter, Anhänge, Antwortsprache und das Ziel der Aufgabe. */
function baseFor(role: string, input: IterativeRefinementRequest, workspace?: NodeAttachmentWorkspace): PromptBuilder {
  return PromptBuilder.create()
    .role(roleWithEmployee(role, input.employee))
    .employee(input.employee?.name, input.employee?.constraint)
    .attachments(attachmentsSectionFor(workspace))
    .responseLanguage(sameAsTask)
    .context("objective", input.objective);
}

/** Bewertung eines Entwurfs; die Kriterien des Nutzers sind die Aufgabe, damit die Antwortsprache passt. */
export function evaluationPrompt(
  input: IterativeRefinementRequest, draft: string, workspace?: NodeAttachmentWorkspace,
): LlmPrompt {
  return baseFor(reviewerRole, input, workspace)
    .outputFormat([
      "Set satisfied to true only if the draft fully meets every criterion.",
      "In critique, name concretely what is missing or wrong; if satisfied, state briefly why.",
    ].join(" "))
    .task(input.critiquePrompt)
    .context("draft", draft)
    .build();
}

/** Wie `evaluationPrompt`, aber für Modelle ohne strukturierte Ausgabe: JSON als Text. */
export function evaluationTextPrompt(
  input: IterativeRefinementRequest, draft: string, workspace?: NodeAttachmentWorkspace,
): LlmPrompt {
  return baseFor(reviewerRole, input, workspace)
    .outputFormat("Answer only with a JSON object of the form {\"critique\": string, \"satisfied\": boolean}.")
    .task(input.critiquePrompt)
    .context("draft", draft)
    .build();
}

/** Überarbeitung eines Entwurfs anhand der Bewertung. */
export function improvementPrompt(
  input: IterativeRefinementRequest, draft: string, critique: string, workspace?: NodeAttachmentWorkspace,
): LlmPrompt {
  const instructions = input.optimizerPrompt.trim() || "Improve the draft precisely and purposefully.";
  return baseFor(optimizerRole, input, workspace)
    .task(instructions)
    .context("current_draft", draft)
    .context("feedback", critique)
    .build();
}
