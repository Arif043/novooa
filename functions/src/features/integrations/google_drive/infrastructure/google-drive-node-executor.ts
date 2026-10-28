import {ok} from "neverthrow";
import {executedNode, type NodeExecutor} from "../../../task_execution/domain/executors/node-executor.js";
import {type GoogleAccessTokens} from "../../../google_accounts/domain/repositories/google-access-tokens.js";
import {type GoogleDriveActionRegistry} from "../domain/google-drive-action.js";
import {GoogleDriveError} from "../domain/google-drive-error.js";
import {GoogleDriveClient} from "./google-drive-client.js";
import {recordExternalAction} from "../../external-action-effect.js";

/** Führt die Aktion des Bausteins aus (`config.action`); jede Aktion ist für Nutzer:innen ein eigener Baustein. */
export function createGoogleDriveNodeExecutor(
  actions: GoogleDriveActionRegistry,
  tokens: GoogleAccessTokens,
  request: typeof fetch = fetch,
): NodeExecutor {
  return {
    primitive: "googleDrive",
    async execute(node, runContext) {
      if (node.config.primitive !== "googleDrive") throw new Error("Der Baustein ist keine Google-Drive-Aktion.");
      const config = node.config;
      const action = actions.find(config.action);
      if (action === undefined) throw new GoogleDriveError(`Die Google-Drive-Aktion „${config.action}“ ist unbekannt.`);
      if (!config.accountId) throw new GoogleDriveError("Bitte wähle das Google-Konto.");
      const resolver = runContext.templateExpressionResolver;
      const outputs = await action.execute({
        drive: new GoogleDriveClient(tokens, config.accountId, request), teamId: runContext.teamId, params: config.params,
        resolveText: (template) => resolver.resolveText(template),
        resolveValue: (template) => resolver.resolveValue(template),
        files: {reader: runContext.fileContentReader, store: runContext.teamFileStore},
      });
      recordExternalAction(runContext.effects, "googleDrive", action, outputs);
      return ok(executedNode(node, outputs));
    },
  };
}
