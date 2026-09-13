import {type SignedLocalRuntimeLicense} from
  "../../../licensing/domain/entities/local-runtime-license-lease.js";
import {type LocalRuntimePushDevice} from
  "../../domain/entities/local-runtime-push.js";
import {type PushNotification} from "../../domain/entities/push-notification.js";

export interface LocalRuntimePushRelayClient {
  register(license: SignedLocalRuntimeLicense, device: LocalRuntimePushDevice): Promise<void>;
  remove(license: SignedLocalRuntimeLicense, token: string): Promise<void>;
  send(license: SignedLocalRuntimeLicense, notification: PushNotification): Promise<void>;
}

export class HttpLocalRuntimePushRelayClient
implements LocalRuntimePushRelayClient {
  private readonly endpoint: URL;

  constructor(endpoint: string) {
    this.endpoint = new URL(endpoint);
    if (this.endpoint.protocol !== "https:") {
      throw new Error("Der Push-Relay muss HTTPS verwenden.");
    }
  }

  async register(license: SignedLocalRuntimeLicense, device: LocalRuntimePushDevice): Promise<void> {
    await this.request({type: "registerDevice", license, ...device});
  }

  async remove(license: SignedLocalRuntimeLicense, token: string): Promise<void> {
    await this.request({type: "removeDevice", license, token});
  }

  async send(
    license: SignedLocalRuntimeLicense,
    notification: PushNotification,
  ): Promise<void> {
    await this.request({type: "send", license, ...notification});
  }

  private async request(body: object): Promise<void> {
    const response = await fetch(this.endpoint, {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) throw new Error("Der Push-Relay hat die Anfrage abgelehnt.");
  }
}

export class UnavailableLocalRuntimePushRelayClient
implements LocalRuntimePushRelayClient {
  async register(): Promise<void> {
    throw unavailable();
  }

  async remove(): Promise<void> {
    throw unavailable();
  }

  async send(): Promise<void> {
    throw unavailable();
  }
}

function unavailable(): Error {
  return new Error("Der novooa Push-Relay ist nicht konfiguriert.");
}
