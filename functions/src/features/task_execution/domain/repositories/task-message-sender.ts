export type TaskMessageKind = "email" | "whatsapp" | "sms";

export type SendTaskMessageInput = {
  teamId: string;
  kind: TaskMessageKind;
  recipient: string;
  body: string;
};

export type SentTaskMessage = {
  outboundId: string;
  providerMessageId: string;
  channelId: string;
};

export interface TaskMessageSender {
  send(input: SendTaskMessageInput): Promise<SentTaskMessage>;
}
