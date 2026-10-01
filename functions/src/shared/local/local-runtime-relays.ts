import {
  HttpRuntimeMailRelayClient,
  type RuntimeMailRelayClient,
  UnavailableRuntimeMailRelayClient,
} from "../../features/communication/infrastructure/local/runtime-mail-relay-client.js";
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

export function mailRelayFromEnvironment(): RuntimeMailRelayClient {
  const endpoint = process.env.LOCAL_RUNTIME_MAIL_RELAY_URL?.trim();
  return endpoint ? new HttpRuntimeMailRelayClient(endpoint) : new UnavailableRuntimeMailRelayClient();
}
