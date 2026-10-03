import {getRemoteConfig, type ServerTemplate} from "firebase-admin/remote-config";
import {initializeAdminApp} from "../../../../shared/firebase/firestore-db.js";
import {logException, logInfo} from "../../../../shared/logging/logger.js";
import {assistantModelNameFrom} from "../../domain/entities/assistant-model-name.js";
import {type AssistantModelSettings} from "../../domain/repositories/assistant-model-settings.js";
import {CachedAssistantModelSettings} from "../../domain/usecases/cached-assistant-model-settings.js";

export const assistantModelKey = "assistant_model";

/**
 * Liest den Modellnamen des KI-Agenten aus Firebase Remote Config (Server-
 * Template, Parameter `assistant_model`). Änderungen in der Console wirken
 * nach spätestens fünf Minuten, ohne Deploy (siehe
 * [CachedAssistantModelSettings]). Ist der Parameter leer oder ungültig,
 * gilt kein Modell — dann greift der Standard aus `ai-models.ts`.
 */
export class RemoteConfigAssistantModel implements AssistantModelSettings {
  private template: ServerTemplate | undefined;
  private readonly cached: CachedAssistantModelSettings;

  constructor(
    private readonly createTemplate: () => ServerTemplate = () => {
      // Remote Config braucht die Admin-App; sie wird sonst erst beim ersten Firestore-Zugriff angelegt.
      initializeAdminApp();
      return getRemoteConfig().initServerTemplate({defaultConfig: {[assistantModelKey]: ""}});
    },
    now: () => number = Date.now,
  ) {
    this.cached = new CachedAssistantModelSettings(
      () => this.readCurrent(),
      (error) => logException("assistant_model.remote_config_failed", error),
      now,
    );
  }

  modelName(): Promise<string | null> {
    return this.cached.modelName();
  }

  /** Liest den Wert frisch aus Remote Config, ohne den Cache zu benutzen. */
  async readCurrent(): Promise<string | null> {
    this.template ??= this.createTemplate();
    await this.template.load();
    const raw = this.template.evaluate().getString(assistantModelKey);
    const name = assistantModelNameFrom(raw);
    if (name === null && raw.trim() !== "") {
      logInfo("assistant_model.remote_config_invalid", {value: raw.slice(0, 100)});
    }
    return name;
  }
}
