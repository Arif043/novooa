type TwilioMessageEvent = {
  messageSid: string;
  from: string;
  to: string;
  body: string;
  channel: "whatsapp" | "sms";
  media: {url: string; contentType: string}[];
  raw: Record<string, string>;
};

export type ChannelKind = "whatsapp" | "sms" | "email";
export type ChannelEventType =
  | "emailReceived"
  | "whatsappMessageReceived"
  | "smsMessageReceived";

type BaseChannelEvent = {
  type: ChannelEventType;
  provider: "twilio" | "sendgrid" | "fake";
  providerMessageId: string;
  receivedAt: string;
  raw: Record<string, string>;
};

export type EmailReceivedEvent = BaseChannelEvent & {
  type: "emailReceived";
  senderEmail: string;
  recipientEmail: string;
  subject: string;
  message: string;
};

export type WhatsappMessageReceivedEvent = BaseChannelEvent & {
  type: "whatsappMessageReceived";
  senderPhoneNumber: string;
  recipientPhoneNumber: string;
  message: string;
  media: {
    url: string;
    contentType: string;
  }[];
};

export type SmsMessageReceivedEvent = BaseChannelEvent & {
  type: "smsMessageReceived";
  senderPhoneNumber: string;
  recipientPhoneNumber: string;
  message: string;
  media: {
    url: string;
    contentType: string;
  }[];
};

export type ChannelMessageEvent =
  | EmailReceivedEvent
  | WhatsappMessageReceivedEvent
  | SmsMessageReceivedEvent;

export function channelMessageEventFromTwilio(
  event: TwilioMessageEvent,
): SmsMessageReceivedEvent | WhatsappMessageReceivedEvent {
  const messageEvent = {
    provider: "twilio" as const,
    providerMessageId: event.messageSid,
    receivedAt: new Date().toISOString(),
    senderPhoneNumber: phoneNumberFrom(event.from),
    recipientPhoneNumber: phoneNumberFrom(event.to),
    message: event.body,
    media: event.media,
    raw: event.raw,
  };
  if (event.channel === "whatsapp") {
    return {...messageEvent, type: "whatsappMessageReceived"};
  }
  return {...messageEvent, type: "smsMessageReceived"};
}

export function channelKindFromEvent(event: ChannelMessageEvent): ChannelKind {
  if (event.type === "emailReceived") return "email";
  if (event.type === "smsMessageReceived") return "sms";
  return "whatsapp";
}

export function messageFromEvent(event: ChannelMessageEvent): string {
  return event.message;
}

export function senderFromEvent(event: ChannelMessageEvent): string {
  if (event.type === "emailReceived") return event.senderEmail;
  return event.senderPhoneNumber;
}

export function recipientFromEvent(event: ChannelMessageEvent): string {
  if (event.type === "emailReceived") return event.recipientEmail;
  return event.recipientPhoneNumber;
}

function phoneNumberFrom(value: string): string {
  return value.startsWith("whatsapp:") ? value.slice("whatsapp:".length) : value;
}
