import {type NodeExecutorRegistry} from "../task_execution/infrastructure/genkit/runner/node-executor-registry.js";
import {type OutboundHttpClient} from "../connections/domain/repositories/outbound-http-client.js";
import {defaultEventTriggerSources, type EventTriggerSourceRegistry} from "../scheduling/domain/entities/event-trigger-source-registry.js";
import {type WebhookInterpreter} from "../webhooks/domain/entities/webhook-interpreter.js";
import {type IntegrationPlugin} from "./integration-plugin.js";
import {shopwarePlugin} from "./shopware/shopware-plugin.js";

/** Alle eingebauten Plugins. Ein neues Plugin wird hier eingetragen und sonst nirgends. */
export const integrationPlugins: readonly IntegrationPlugin[] = [shopwarePlugin];

/** Meldet die Executoren aller Plugins an; gibt die Registry zur Verkettung zurück. */
export function registerIntegrationPlugins(
  registry: NodeExecutorRegistry,
  plugins: readonly IntegrationPlugin[] = integrationPlugins,
  sources: EventTriggerSourceRegistry = defaultEventTriggerSources,
): NodeExecutorRegistry {
  for (const plugin of plugins) {
    for (const executor of plugin.executors) registry.register(executor);
    for (const trigger of plugin.eventTriggers ?? []) sources.register(trigger.source);
  }
  return registry;
}

/** Je Quelle der Plugins der Interpreter, der eingehende Aufrufe auswertet. */
export function integrationWebhookInterpreters(
  http: OutboundHttpClient,
  plugins: readonly IntegrationPlugin[] = integrationPlugins,
): ReadonlyMap<string, WebhookInterpreter> {
  const interpreters = new Map<string, WebhookInterpreter>();
  for (const plugin of plugins) {
    for (const trigger of plugin.eventTriggers ?? []) interpreters.set(trigger.source.id, trigger.interpreter({http}));
  }
  return interpreters;
}
