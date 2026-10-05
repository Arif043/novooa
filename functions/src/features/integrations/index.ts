import {type NodeExecutorRegistry} from "../task_execution/infrastructure/genkit/runner/node-executor-registry.js";
import {type IntegrationPlugin} from "./integration-plugin.js";
import {shopwarePlugin} from "./shopware/shopware-plugin.js";

/** Alle eingebauten Plugins. Ein neues Plugin wird hier eingetragen und sonst nirgends. */
export const integrationPlugins: readonly IntegrationPlugin[] = [shopwarePlugin];

/** Meldet die Executoren aller Plugins an; gibt die Registry zur Verkettung zurück. */
export function registerIntegrationPlugins(
  registry: NodeExecutorRegistry,
  plugins: readonly IntegrationPlugin[] = integrationPlugins,
): NodeExecutorRegistry {
  for (const plugin of plugins) for (const executor of plugin.executors) registry.register(executor);
  return registry;
}
