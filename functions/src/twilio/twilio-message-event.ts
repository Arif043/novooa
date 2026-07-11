export type TwilioMedia = {
  url: string;
  contentType: string;
};

export type TwilioMessageEvent = {
  accountSid: string;
  messageSid: string;
  from: string;
  to: string;
  body: string;
  channel: "whatsapp" | "sms";
  media: TwilioMedia[];
  raw: Record<string, string>;
};

export function twilioMessageEventFrom(
  fields: Record<string, string>,
): TwilioMessageEvent {
  const from = requiredField(fields, "From");
  const to = requiredField(fields, "To");
  return {
    accountSid: requiredField(fields, "AccountSid"),
    messageSid: messageSidFrom(fields),
    from,
    to,
    body: fields.Body ?? "",
    channel: channelFrom(from, to),
    media: mediaFrom(fields),
    raw: fields,
  };
}

function messageSidFrom(fields: Record<string, string>): string {
  return fields.MessageSid ?? requiredField(fields, "SmsMessageSid");
}

function channelFrom(from: string, to: string): "whatsapp" | "sms" {
  if (from.startsWith("whatsapp:") || to.startsWith("whatsapp:")) {
    return "whatsapp";
  }
  return "sms";
}

function mediaFrom(fields: Record<string, string>): TwilioMedia[] {
  const count = Number(fields.NumMedia ?? "0");
  return Array.from({length: Number.isFinite(count) ? count : 0}, (_, index) => {
    return {
      url: fields[`MediaUrl${index}`] ?? "",
      contentType: fields[`MediaContentType${index}`] ?? "",
    };
  }).filter((item) => item.url.length > 0);
}

function requiredField(fields: Record<string, string>, name: string): string {
  const value = fields[name]?.trim();
  if (value) return value;
  throw new Error(`Twilio field ${name} is required.`);
}
