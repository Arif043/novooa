import {onConfigUpdated} from "firebase-functions/v2/remoteConfig";
import {logException, logInfo} from "../../../../shared/logging/logger.js";
import {syncAssistantModelConfig} from "../../domain/usecases/sync-assistant-model-config.js";
import {publishAssistantModelConfig, readPublishedAssistantModel} from "./assistant-model-config-document.js";
import {RemoteConfigAssistantModel} from "./remote-config-assistant-model.js";

/**
 * Reagiert auf jede Veröffentlichung in Remote Config und führt das Dokument
 * nach, auf das die lokalen Runtimes hören. So erfahren sie eine neue
 * Modellbezeichnung sofort, ohne dass sie die Cloud abfragen.
 */
export const syncAssistantModelConfigOnUpdate = onConfigUpdated(async () => {
  try {
    const outcome = await syncAssistantModelConfig({
      readCurrent: () => new RemoteConfigAssistantModel().readCurrent(),
      readPublished: readPublishedAssistantModel,
      publish: publishAssistantModelConfig,
    });
    logInfo("assistant_model.config_synced", {outcome});
  } catch (error) {
    logException("assistant_model.config_sync_failed", error);
    throw error;
  }
});
