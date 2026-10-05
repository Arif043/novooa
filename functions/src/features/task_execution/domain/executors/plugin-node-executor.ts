import {PluginNotFoundError} from "../../../plugins/domain/entities/stored-plugin.js";
import {type PluginRunner} from "../../../plugins/domain/repositories/plugin-runner.js";
import {type NodeExecutionResult} from "../entities/task.js";
import {type NodeExecutor, executedNode} from "./node-executor.js";

function skipped(nodeId: string, message: string): NodeExecutionResult {
  return {nodeId, primitive: "plugin", status: "skipped", outputs: {}, message};
}

/**
 * Löst den generischen Plugin-Baustein über den `PluginRunner` auf. Ein fehlendes Plugin bricht die Aufgabe nicht ab
 * (z. B. nach Import auf einem Gerät ohne das Plugin), sondern überspringt den Baustein mit einem Hinweis.
 */
export function createPluginNodeExecutor(runner: PluginRunner | undefined): NodeExecutor {
  return {
    primitive: "plugin",
    async execute(node, runContext) {
      if (node.config.primitive !== "plugin") return skipped(node.id, "Der Baustein ist kein Plugin-Baustein.");
      const {pluginId, nodeType} = node.config;
      if (runner === undefined) return skipped(node.id, "Plugins sind in dieser Umgebung nicht verfügbar.");
      const settings = Object.fromEntries(Object.entries(node.config.settings).map(([key, value]) =>
        [key, typeof value === "string" ? runContext.templateExpressionResolver.resolveText(value) : value]));
      try {
        return executedNode(node, await runner.runPrimitive({pluginId, nodeType, settings}));
      } catch (error) {
        if (error instanceof PluginNotFoundError) {
          return skipped(node.id, `Das Plugin „${pluginId}“ ist nicht installiert. Installiere es unter Einstellungen → Plugins.`);
        }
        throw error;
      }
    },
  };
}
