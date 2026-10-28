import {type LlmPrompt} from "../../../language_models/domain/prompting/llm-prompt.js";
import {type PromptBuilder} from "../../../language_models/domain/prompting/prompt-builder.js";
import {type ResponseLanguagePolicy, sameAsTask} from "../../../language_models/domain/prompting/response-language.js";
import {type AssistantLocale} from "../../domain/entities/assistant-locale.js";
import {type AssistantRequest} from "../../domain/entities/assistant-request.js";
import {publicUrlsIn} from "./assistant-url-context-prompt.js";

/**
 * Prompt eines Agenten-Turns: die festen Anweisungen des Agenten, die Antwortsprache der App, der
 * Verlauf aus dem Client, genannte Webseiten und die aktuelle Frage als `<task>`.
 */
export function assistantPrompt(instructions: PromptBuilder, request: AssistantRequest): LlmPrompt {
  return instructions
    .responseLanguage(responseLanguageFor(request.locale))
    .history(request.history.map((message) => ({
      role: message.role === "agent" ? "model" as const : "user" as const,
      text: message.text,
    })))
    .context("public_urls", publicUrlsIn(request.question).join("\n"))
    .task(request.question)
    .build();
}

/** Ältere Clients senden keine Sprache; dann antwortet der Agent in der Sprache der Frage. */
function responseLanguageFor(locale: AssistantLocale | undefined): ResponseLanguagePolicy {
  return locale ? {kind: "fixed", language: locale} : sameAsTask;
}
