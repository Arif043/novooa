import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeRelayLicenseVerifier} from
  "../../../licensing/domain/repositories/runtime-relay-license-verifier.js";
import {
  type RuntimePushDevice,
} from "../entities/runtime-push.js";
import {type PushNotification} from "../entities/push-notification.js";
import {type RuntimePushDeviceStore} from
  "../repositories/runtime-push-device-store.js";
import {type PushNotificationSender} from
  "../repositories/push-notification-sender.js";

export class RuntimePushRelay {
  constructor(
    private readonly licenses: RuntimeRelayLicenseVerifier,
    private readonly devices: RuntimePushDeviceStore,
    private readonly sender: PushNotificationSender,
  ) {}

  async register(
    license: SignedRuntimeLicense,
    device: RuntimePushDevice,
  ): Promise<void> {
    await this.devices.save(await this.licenses.verify(license), device);
  }

  async unregister(
    license: SignedRuntimeLicense,
    token: string,
  ): Promise<void> {
    const active = await this.licenses.verify(license);
    await this.devices.remove(active.licenseId, token);
  }

  async send(
    license: SignedRuntimeLicense,
    notification: PushNotification,
  ): Promise<void> {
    const active = await this.licenses.verify(license);
    await this.sender.sendToRecipient(active.licenseId, notification);
  }
}
