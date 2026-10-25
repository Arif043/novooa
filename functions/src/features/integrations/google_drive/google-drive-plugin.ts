import {type IntegrationPlugin} from "../integration-plugin.js";
import {GoogleDriveActionRegistry} from "./domain/google-drive-action.js";
import {readAction} from "./actions/read-action.js";
import {uploadAction} from "./actions/upload-action.js";
import {createGoogleDriveNodeExecutor} from "./infrastructure/google-drive-node-executor.js";

/** Alle Aktionen des Drive-Bausteins; jede liegt in `actions/` und meldet sich hier an. */
export const googleDriveActions = new GoogleDriveActionRegistry()
  .register(uploadAction)
  .register(readAction);

/**
 * Google Drive mit dem Scope `drive.file`: Speichern überall, Lesen nur freigegebener und selbst angelegter
 * Dateien. Ein Auslöser für neue Dateien braucht den vollen Scope und kommt nach der Google-Verifizierung.
 */
export const googleDrivePlugin: IntegrationPlugin = {
  id: "googleDrive",
  executors: ({googleAccessTokens}) => [createGoogleDriveNodeExecutor(googleDriveActions, googleAccessTokens)],
};
