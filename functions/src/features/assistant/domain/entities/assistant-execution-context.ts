import {type AssistantActor} from "./assistant-actor.js";

export class AssistantExecutionContext {
  constructor(readonly actor: AssistantActor) {}
}
