import {assistantModelNameFrom} from "../../domain/entities/assistant-model-name.js";
import {type AssistantModelSettings} from "../../domain/repositories/assistant-model-settings.js";

/**
 * Der Modellname des KI-Agenten in der lokalen Runtime. Die Cloud führt ihn
 * bei jeder Änderung in Remote Config in einem Firestore-Dokument nach; die
 * Runtime hört darauf (siehe `RuntimeFirebaseSession.listenForAssistantModel`)
 * und ruft [update] auf. Es wird nie nachgefragt. Bricht der Listener ab, bleibt
 * der letzte Name stehen; ohne Dokument gilt das Standardmodell.
 */
export class RuntimeAssistantModel implements AssistantModelSettings {
  private name: string | null = null;

  update(document: {assistantModel?: unknown} | undefined): void {
    this.name = typeof document?.assistantModel === "string"
      ? assistantModelNameFrom(document.assistantModel)
      : null;
  }

  modelName(): Promise<string | null> {
    return Promise.resolve(this.name);
  }
}
