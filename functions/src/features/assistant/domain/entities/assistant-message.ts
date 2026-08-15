export type AssistantRole = "user" | "agent";

export class AssistantMessage {
  constructor(
    readonly role: AssistantRole,
    readonly text: string,
  ) {
    if (text.trim().length === 0) throw new Error("Assistant message text is required.");
  }
}
