import {type EmailReceivedEvent} from "./channel-message-event.js";

export type RuntimeMailRelayEvent = {
  eventId: string;
  connectorId: string;
  event: EmailReceivedEvent;
  createdAt: string;
};

export type RuntimeMailRelayDelivery = RuntimeMailRelayEvent & {
  receipt: string;
  attempt: number;
};

export type RuntimeMailRelayDeadLetter = RuntimeMailRelayEvent & {
  attempts: number;
  failedAt: string;
  lastError: string;
  replayedAt: string | null;
};
