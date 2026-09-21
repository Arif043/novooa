import {
  type RuntimeMailRelayDeadLetter,
  type RuntimeMailRelayDelivery,
  type RuntimeMailRelayEvent,
} from "../entities/runtime-mail-relay-event.js";

export interface RuntimeMailRelayEventStore {
  enqueue(input: {
    licenseId: string;
    workspaceId: string;
    event: RuntimeMailRelayEvent;
  }): Promise<void>;

  lease(input: {
    licenseId: string;
    now: Date;
    limit: number;
  }): Promise<RuntimeMailRelayDelivery[]>;

  acknowledge(input: {
    licenseId: string;
    eventId: string;
    receipt: string;
  }): Promise<void>;

  reject(input: {
    licenseId: string;
    eventId: string;
    receipt: string;
    error: string;
    now: Date;
  }): Promise<void>;

  listDeadLetters(licenseId: string): Promise<RuntimeMailRelayDeadLetter[]>;

  replay(input: {
    licenseId: string;
    eventId: string;
    now: Date;
  }): Promise<void>;
}
