import {
  HttpRuntimeMailRelayClient,
  type RuntimeMailRelayClient,
  UnavailableRuntimeMailRelayClient,
} from "../../features/communication/infrastructure/local/runtime-mail-relay-client.js";
import {type ScriptExecutorFactory} from "../../features/task_execution/domain/executors/script-executor.js";
import {
  createContainerScriptExecutorFactory,
  unavailableScriptExecutorFactory,
} from "../../features/task_execution/infrastructure/local/container-script-executor.js";
import {
  HttpRuntimeTaskBuilderRelayClient,
  type RuntimeTaskBuilderRelayClient,
  UnavailableRuntimeTaskBuilderRelayClient,
} from "../../features/task_execution/infrastructure/local/runtime-task-builder-relay-client.js";
import {
  HttpRuntimePushRelayClient,
  type RuntimePushRelayClient,
  UnavailableRuntimePushRelayClient,
} from "../../features/notifications/infrastructure/local/runtime-push-relay-client.js";

/** Ohne konfigurierte Relay-URL meldet der Client „nicht verfügbar“, statt zu scheitern. */
export function pushRelayFromEnvironment(): RuntimePushRelayClient {
  const endpoint = process.env.LOCAL_RUNTIME_PUSH_RELAY_URL?.trim();
  return endpoint ? new HttpRuntimePushRelayClient(endpoint) : new UnavailableRuntimePushRelayClient();
}

/** Scripts laufen im abgeschotteten Container; ohne Adresse läuft keines, statt ungeschützt in der Runtime. */
export function scriptExecutorFactoryFromEnvironment(): ScriptExecutorFactory {
  const endpoint = process.env.SCRIPT_RUNNER_URL?.trim();
  return endpoint ? createContainerScriptExecutorFactory(endpoint) : unavailableScriptExecutorFactory();
}

export function taskBuilderRelayFromEnvironment(): RuntimeTaskBuilderRelayClient {
  const endpoint = process.env.LOCAL_RUNTIME_TASK_BUILDER_RELAY_URL?.trim();
  return endpoint ? new HttpRuntimeTaskBuilderRelayClient(endpoint) : new UnavailableRuntimeTaskBuilderRelayClient();
}

export function mailRelayFromEnvironment(): RuntimeMailRelayClient {
  const endpoint = process.env.LOCAL_RUNTIME_MAIL_RELAY_URL?.trim();
  return endpoint ? new HttpRuntimeMailRelayClient(endpoint) : new UnavailableRuntimeMailRelayClient();
}
