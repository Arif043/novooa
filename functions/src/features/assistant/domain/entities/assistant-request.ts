import {type AssistantLocale} from "./assistant-locale.js";
import {type AssistantMessage} from "./assistant-message.js";

export class AssistantRequest {
  readonly history: readonly AssistantMessage[];

  constructor(
    readonly question: string,
    history: readonly AssistantMessage[],
    readonly locale?: AssistantLocale,
  ) {
    if (question.trim().length === 0) throw new Error("Assistant question is required.");
    this.history = [...history];
  }
}
