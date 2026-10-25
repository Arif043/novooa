import {type OutboundHttpClient} from "../connections/domain/repositories/outbound-http-client.js";
import {type EventTriggerSourceDefinition} from "../scheduling/domain/entities/event-trigger-source-registry.js";
import {type WebhookInterpreter} from "../webhooks/domain/entities/webhook-interpreter.js";
import {type NodeExecutor} from "../task_execution/domain/executors/node-executor.js";
import {type GoogleAccessTokens} from "../google_accounts/domain/repositories/google-access-tokens.js";

/**
 * Ein fest eingebautes Plugin: ein Modul, das ein externes System an novooa anschließt und dafür Bausteine mitbringt.
 * Der Kern importiert nichts aus `features/integrations`; verdrahtet wird nur in `shared/local` (siehe
 * `registerIntegrationPlugins`). Der Vertrag wächst mit den Plugins, nicht vorab.
 */
export type IntegrationPlugin = {
  id: string;
  /**
   * Executoren der Bausteine, die das Plugin mitbringt (Primitive stehen in `workflowPrimitives`). Die
   * Komposition reicht die Dienste der Runtime herein, die sie brauchen.
   */
  executors: (dependencies: IntegrationPluginDependencies) => readonly NodeExecutor[];
  /** Auslöser, die das Plugin mitbringt: Quelle und der Interpreter, der Aufrufe der Quelle auswertet. */
  eventTriggers?: readonly IntegrationEventTrigger[];
};

/** Dienste der Runtime, die Plugins nutzen dürfen. Wächst mit dem Bedarf der Plugins. */
export type IntegrationPluginDependencies = {
  googleAccessTokens: GoogleAccessTokens;
};

export type IntegrationEventTrigger = {
  source: EventTriggerSourceDefinition;
  interpreter: (dependencies: {http: OutboundHttpClient}) => WebhookInterpreter;
};
