import {
  type SendTaskMessageInput,
  type SentTaskMessage,
  type TaskMessageSender,
} from "../../domain/repositories/task-message-sender.js";
import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeMailRelayClient} from
  "../../../communication/infrastructure/local/runtime-mail-relay-client.js";

export class LocalTaskMessageSender implements TaskMessageSender {
  constructor(
    private readonly signedLicense: () => SignedRuntimeLicense | null,
    private readonly relay: RuntimeMailRelayClient,
  ) {}

  async send(input: SendTaskMessageInput): Promise<SentTaskMessage> {
    if (input.kind !== "email") throw new Error("Lokale WhatsApp- und SMS-Nachrichten werden noch nicht unterstützt.");
    const license = this.signedLicense();
    if (license === null) throw new Error("Die lokale Runtime hat keine aktive Lizenz.");
    return this.relay.sendEmail(license, {
      connectorId: input.connectorId, recipient: input.recipient,
      subject: input.subject ?? "Nachricht von novooa", body: input.body,
    });
  }
}
