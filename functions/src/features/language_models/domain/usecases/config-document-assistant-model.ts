import {assistantModelNameFrom} from "../entities/assistant-model-name.js";
import {type AssistantModelSettings} from "../repositories/assistant-model-settings.js";

/** Das Konfigurationsdokument, wie es in Firestore liegt; `undefined`, wenn es fehlt. */
export type AssistantModelConfigDocument = {assistantModel?: unknown} | undefined;

/**
 * Der Modellname des KI-Agenten aus dem Konfigurationsdokument, das die Cloud
 * bei jeder Änderung in Remote Config nachführt. Es gibt keinen Cache: Das
 * Lesen eines Dokuments ist billig, und so wirkt eine Änderung sofort.
 * Existiert das Dokument noch nicht (Einrichtung, noch nichts veröffentlicht),
 * gilt ersatzweise [fallback] — in der Cloud Remote Config selbst.
 */
export class ConfigDocumentAssistantModel implements AssistantModelSettings {
  constructor(
    private readonly readDocument: () => Promise<AssistantModelConfigDocument>,
    private readonly fallback: AssistantModelSettings,
  ) {}

  async modelName(): Promise<string | null> {
    const document = await this.readDocument();
    if (document === undefined) return this.fallback.modelName();
    return typeof document.assistantModel === "string"
      ? assistantModelNameFrom(document.assistantModel)
      : null;
  }
}
