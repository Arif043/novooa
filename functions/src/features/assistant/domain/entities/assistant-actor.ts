export class AssistantActor {
  constructor(readonly id: string) {
    if (id.trim().length === 0) throw new Error("Assistant actor ID is required.");
  }
}
