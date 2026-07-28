import {
  type SentTaskMessage,
  type SendTaskMessageInput,
  type TaskMessageSender,
} from "../../../task_execution/domain/repositories/task-message-sender.js";
import {
  requiredSendgridApiKey,
  sendgridApiKey,
} from "../sendgrid/sendgrid-secrets.js";
import {sendTeamEmailMessage} from "../sendgrid/team-email-message-sender.js";
import {
  requiredSecret,
  twilioAccountSid,
  twilioAuthToken,
} from "../twilio/twilio-secrets.js";
import {sendTeamChannelMessage} from "../twilio/team-channel-message-sender.js";

export class FirebaseTaskMessageSender implements TaskMessageSender {
  async send(input: SendTaskMessageInput): Promise<SentTaskMessage> {
    if (input.kind === "email") return this.sendEmail(input);
    return this.sendPhoneMessage({...input, kind: input.kind});
  }

  private async sendEmail(input: SendTaskMessageInput): Promise<SentTaskMessage> {
    return sendTeamEmailMessage({
      teamId: input.teamId,
      recipient: input.recipient,
      subject: "Nachricht von novooa",
      body: input.body,
      apiKey: requiredSendgridApiKey(sendgridApiKey),
    });
  }

  private async sendPhoneMessage(
    input: SendTaskMessageInput & {kind: "whatsapp" | "sms"},
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
