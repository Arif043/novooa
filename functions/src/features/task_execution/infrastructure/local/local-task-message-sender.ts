import {
  type SendTaskMessageInput,
  type SentTaskMessage,
  type TaskMessageSender,
} from "../../domain/repositories/task-message-sender.js";

export class LocalTaskMessageSender implements TaskMessageSender {
  async send(_input: SendTaskMessageInput): Promise<SentTaskMessage> {
    throw new Error("Lokale Nachrichten werden erst über den novooa Relay versendet.");
  }
}
