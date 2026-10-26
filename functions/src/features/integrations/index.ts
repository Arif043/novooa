import {type NodeExecutorRegistry} from "../task_execution/infrastructure/genkit/runner/node-executor-registry.js";
import {type OutboundHttpClient} from "../connections/domain/repositories/outbound-http-client.js";
import {defaultEventTriggerSources, type EventTriggerSourceRegistry} from "../scheduling/domain/entities/event-trigger-source-registry.js";
import {type WebhookInterpreter} from "../webhooks/domain/entities/webhook-interpreter.js";
import {type PluginAvailability} from "../plugins/domain/repositories/plugin-activation-store.js";
import {type IntegrationPlugin, type IntegrationPluginDependencies} from "./integration-plugin.js";
import {executorEnabledBy, interpreterEnabledBy} from "./plugin-activation-guard.js";
import {shopwarePlugin} from "./shopware/shopware-plugin.js";
import {googleDrivePlugin} from "./google_drive/google-drive-plugin.js";

/** Alle eingebauten Plugins. Ein neues Plugin wird hier eingetragen und sonst nirgends. */
export const integrationPlugins: readonly IntegrationPlugin[] = [shopwarePlugin, googleDrivePlugin];

/** Kennungen aller eingebauten Plugins, z. B. für die Liste in den Einstellungen. */
export const integrationPluginIds: readonly string[] = integrationPlugins.map((plugin) => plugin.id);

/**
 * Meldet die Executoren aller Plugins an; gibt die Registry zur Verkettung zurück. Jeder Executor fragt vor dem
 * Ausführen, ob sein Plugin im Arbeitsbereich aktiv ist.
 */
export function registerIntegrationPlugins(
  registry: NodeExecutorRegistry,
  dependencies: IntegrationPluginDependencies,
  availability: PluginAvailability,
  plugins: readonly IntegrationPlugin[] = integrationPlugins,
  sources: EventTriggerSourceRegistry = defaultEventTriggerSources,
): NodeExecutorRegistry {
  for (const plugin of plugins) {
    for (const executor of plugin.executors(dependencies)) {
      registry.register(executorEnabledBy(plugin.id, executor, availability));
    }
    for (const trigger of plugin.eventTriggers ?? []) sources.register(trigger.source);
  }
  return registry;
}

/** Je Quelle der Plugins der Interpreter, der eingehende Aufrufe auswertet. */
export function integrationWebhookInterpreters(
  http: OutboundHttpClient,
  availability: PluginAvailability,
  plugins: readonly IntegrationPlugin[] = integrationPlugins,
): ReadonlyMap<string, WebhookInterpreter> {
  const interpreters = new Map<string, WebhookInterpreter>();
  for (const plugin of plugins) {
    for (const trigger of plugin.eventTriggers ?? []) {
      interpreters.set(trigger.source.id, interpreterEnabledBy(plugin.id, trigger.interpreter({http}), availability));
    }
  }
  return interpreters;
}
