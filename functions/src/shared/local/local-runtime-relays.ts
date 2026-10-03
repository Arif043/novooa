import {
  HttpRuntimeMailRelayClient,
  type RuntimeMailRelayClient,
  UnavailableRuntimeMailRelayClient,
} from "../../features/communication/infrastructure/local/runtime-mail-relay-client.js";
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

export function taskBuilderRelayFromEnvironment(): RuntimeTaskBuilderRelayClient {
  const endpoint = process.env.LOCAL_RUNTIME_TASK_BUILDER_RELAY_URL?.trim();
  return endpoint ? new HttpRuntimeTaskBuilderRelayClient(endpoint) : new UnavailableRuntimeTaskBuilderRelayClient();
}

export function mailRelayFromEnvironment(): RuntimeMailRelayClient {
  const endpoint = process.env.LOCAL_RUNTIME_MAIL_RELAY_URL?.trim();
  return endpoint ? new HttpRuntimeMailRelayClient(endpoint) : new UnavailableRuntimeMailRelayClient();
}
