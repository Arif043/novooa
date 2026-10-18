import {ok} from "neverthrow";
import {executedNode, type NodeExecutor} from "../../../task_execution/domain/executors/node-executor.js";
import {type ShopwareActionRegistry} from "../domain/shopware-action.js";
import {ShopwareError} from "../domain/shopware-error.js";
import {ShopwareClient} from "./shopware-client.js";

/** Für Aktionen ohne Verbindung: jeder Zugriff wäre ein Programmierfehler. */
const unusableClient = new ShopwareClient(
  {send: () => Promise.reject(new ShopwareError("Interner Fehler: Diese Aktion hat keine Verbindung."))}, "", "",
);

/** Führt die Aktion des Bausteins aus (`config.action`); jede Aktion ist für Nutzer:innen ein eigener Baustein. */
export function createShopwareNodeExecutor(actions: ShopwareActionRegistry): NodeExecutor {
  return {
    primitive: "shopware",
    async execute(node, runContext) {
      if (node.config.primitive !== "shopware") throw new Error("Der Baustein ist keine Shopware-Aktion.");
      const config = node.config;
      const action = actions.find(config.action);
      if (action === undefined) throw new ShopwareError(`Die Shopware-Aktion „${config.action}“ ist unbekannt.`);
      const resolveText = (template: string) => runContext.templateExpressionResolver.resolveText(template);
      const event: unknown = runContext.input.event;
      if (action.usesConnection === false) {
        const outputs = await action.execute({client: unusableClient, params: config.params, resolveText, event});
        return ok(executedNode(node, outputs));
      }
      const http = runContext.outboundHttpClient;
      if (http === undefined) throw new ShopwareError("Shopware-Aktionen sind in dieser Betriebsvariante nicht verfügbar.");
      if (config.connectionId === undefined || config.connectionId === "") {
        throw new ShopwareError("Bitte wähle die Verbindung zu deinem Shopware-Shop.");
      }
      const outputs = await action.execute({
        client: new ShopwareClient(http, runContext.teamId, config.connectionId), params: config.params, resolveText, event,
      });
      return ok(executedNode(node, outputs));
    },
  };
}
