import {err} from "neverthrow";
import {nodeFailures} from "../task_execution/domain/entities/node-failures.js";
import {type NodeExecutor} from "../task_execution/domain/executors/node-executor.js";
import {type WebhookInterpreter} from "../webhooks/domain/entities/webhook-interpreter.js";
import {type PluginAvailability} from "../plugins/domain/repositories/plugin-activation-store.js";

/** Bausteine eines deaktivierten Plugins scheitern mit `pluginDisabled`; aktiviert läuft der Executor unverändert. */
export function executorEnabledBy(pluginId: string, executor: NodeExecutor, availability: PluginAvailability): NodeExecutor {
  return {
    primitive: executor.primitive,
    async execute(node, runContext) {
      if (await availability.isEnabled(runContext.teamId, pluginId)) return executor.execute(node, runContext);
      return err(nodeFailures.pluginDisabled(pluginId));
    },
  };
}

/** Auslöser eines deaktivierten Plugins starten keine Läufe; der Aufruf gilt trotzdem als angenommen. */
export function interpreterEnabledBy(
  pluginId: string, interpreter: WebhookInterpreter, availability: PluginAvailability,
): WebhookInterpreter {
  return {
    async interpret(trigger, request) {
      if (!await availability.isEnabled(trigger.teamId, pluginId)) return [];
      return interpreter.interpret(trigger, request);
    },
  };
}
