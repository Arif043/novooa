import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeRelayLicenseVerifier} from
  "../../../licensing/domain/repositories/runtime-relay-license-verifier.js";
import {type RuntimeMailRelayDelivery} from
  "../entities/runtime-mail-relay-event.js";
import {type RuntimeMailRelayEventStore} from
  "../repositories/runtime-mail-relay-event-store.js";

export class RuntimeMailRelay {
  constructor(
    private readonly licenses: RuntimeRelayLicenseVerifier,
    private readonly events: RuntimeMailRelayEventStore,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async pull(
    license: SignedRuntimeLicense,
    limit: number,
  ): Promise<RuntimeMailRelayDelivery[]> {
    const verified = await this.licenses.verify(license);
    return this.events.lease({licenseId: verified.licenseId, limit, now: this.now()});
  }

  async acknowledge(input: {
    license: SignedRuntimeLicense;
    eventId: string;
    receipt: string;
  }): Promise<void> {
    const license = await this.licenses.verify(input.license);
    await this.events.acknowledge({
      licenseId: license.licenseId,
      eventId: input.eventId,
      receipt: input.receipt,
    });
  }

  async reject(input: {
    license: SignedRuntimeLicense;
    eventId: string;
    receipt: string;
    error: string;
  }): Promise<void> {
    const license = await this.licenses.verify(input.license);
    await this.events.reject({
      licenseId: license.licenseId,
      eventId: input.eventId,
      receipt: input.receipt,
      error: input.error,
      now: this.now(),
    });
  }

  async deadLetters(license: SignedRuntimeLicense) {
    const verified = await this.licenses.verify(license);
    return this.events.listDeadLetters(verified.licenseId);
  }

  async replay(input: {
    license: SignedRuntimeLicense;
    eventId: string;
  }): Promise<void> {
    const license = await this.licenses.verify(input.license);
    await this.events.replay({
      licenseId: license.licenseId,
      eventId: input.eventId,
      now: this.now(),
    });
  }
}
