export type TaskMessageKind = "email" | "whatsapp" | "sms";

type BaseTaskMessageInput = {
  teamId: string;
  recipient: string;
  subject?: string;
  body: string;
};

export type SendTaskEmailInput = BaseTaskMessageInput & {
  kind: "email";
  connectorId: string;
};

export type SendTaskPhoneMessageInput = BaseTaskMessageInput & {
  kind: "whatsapp" | "sms";
};

export type SendTaskMessageInput =
  | SendTaskEmailInput
  | SendTaskPhoneMessageInput;

export type SentTaskMessage = {
  outboundId: string;
  providerMessageId: string;
  channelId: string;
};

export interface TaskMessageSender {
  send(input: SendTaskMessageInput): Promise<SentTaskMessage>;
}
