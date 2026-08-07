import {
  type SendTaskEmailInput,
  type SentTaskMessage,
  type SendTaskPhoneMessageInput,
  type SendTaskMessageInput,
  type TaskMessageSender,
} from "../../../task_execution/domain/repositories/task-message-sender.js";
import {FirestoreMailConnectorRepository} from
  "./firestore-mail-connector-repository.js";
import {
  mailConnectorCipher,
} from "../microsoft_graph/microsoft-graph-config.js";
import {sendTeamMicrosoftGraphEmail} from
  "../microsoft_graph/team-microsoft-graph-email-sender.js";
import {
  requiredSecret,
  twilioAccountSid,
  twilioAuthToken,
} from "../twilio/twilio-secrets.js";
import {sendTeamChannelMessage} from "../twilio/team-channel-message-sender.js";

export class FirebaseTaskMessageSender implements TaskMessageSender {
  async send(input: SendTaskMessageInput): Promise<SentTaskMessage> {
    if (input.kind === "email") return this.sendConnectorEmail(input);
    return this.sendPhoneMessage(input);
  }

  private sendConnectorEmail(
    input: SendTaskEmailInput,
  ): Promise<SentTaskMessage> {
    return sendTeamMicrosoftGraphEmail({
      teamId: input.teamId,
      connectorId: input.connectorId,
      recipient: input.recipient,
      subject: input.subject || "Nachricht von novooa",
      body: input.body,
      repository: new FirestoreMailConnectorRepository(mailConnectorCipher()),
    });
  }

  private async sendPhoneMessage(
    input: SendTaskPhoneMessageInput,
  ): Promise<SentTaskMessage> {
    return sendTeamChannelMessage({
      teamId: input.teamId,
      kind: input.kind,
      recipient: input.recipient,
      body: input.body,
      parentAccountSid: requiredSecret(twilioAccountSid),
      authToken: requiredSecret(twilioAuthToken),
    });
  }
}
