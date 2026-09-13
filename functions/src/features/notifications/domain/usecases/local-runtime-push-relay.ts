import {type SignedLocalRuntimeLicense} from
  "../../../licensing/domain/entities/local-runtime-license-lease.js";
import {type LocalRuntimeRelayLicenseVerifier} from
  "../../../licensing/domain/repositories/local-runtime-relay-license-verifier.js";
import {
  type LocalRuntimePushDevice,
} from "../entities/local-runtime-push.js";
import {type PushNotification} from "../entities/push-notification.js";
import {type LocalRuntimePushDeviceStore} from
  "../repositories/local-runtime-push-device-store.js";
import {type PushNotificationSender} from
  "../repositories/push-notification-sender.js";

export class LocalRuntimePushRelay {
  constructor(
    private readonly licenses: LocalRuntimeRelayLicenseVerifier,
    private readonly devices: LocalRuntimePushDeviceStore,
    private readonly sender: PushNotificationSender,
  ) {}

  async register(
    license: SignedLocalRuntimeLicense,
    device: LocalRuntimePushDevice,
  ): Promise<void> {
    await this.devices.save(await this.licenses.verify(license), device);
  }

  async unregister(
    license: SignedLocalRuntimeLicense,
    token: string,
  ): Promise<void> {
    const active = await this.licenses.verify(license);
    await this.devices.remove(active.licenseId, token);
  }

  async send(
    license: SignedLocalRuntimeLicense,
    notification: PushNotification,
  ): Promise<void> {
    const active = await this.licenses.verify(license);
    await this.sender.sendToRecipient(active.licenseId, notification);
  }
}
