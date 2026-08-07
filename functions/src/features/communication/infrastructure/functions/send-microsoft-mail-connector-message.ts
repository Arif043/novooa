import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "genkit";
import {logException, logInfo} from "../../../../shared/logging/logger.js";
import {currentTeamIdForUid} from
  "../../../teams/infrastructure/firebase/firebase-team-context.js";
import {FirestoreMailConnectorRepository} from
  "../firebase/firestore-mail-connector-repository.js";
import {
  mailConnectorCipher,
  mailConnectorEncryptionKey,
  microsoftGraphClientSecret,
} from "../microsoft_graph/microsoft-graph-config.js";
import {sendTeamMicrosoftGraphEmail} from
  "../microsoft_graph/team-microsoft-graph-email-sender.js";

const inputSchema = z.object({
  connectorId: z.string().min(1).max(120),
  recipient: z.string().min(3).max(320),
  subject: z.string().min(1).max(998),
  body: z.string().min(1).max(100000),
});

export const sendMicrosoftMailConnectorMessage = onCall(
  {secrets: [microsoftGraphClientSecret, mailConnectorEncryptionKey]},
  async (request) => {
    const input = inputFrom(request.data);
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Anmeldung erforderlich.");
    return sendMessage(await currentTeamIdForUid(uid), input);
  },
);

async function sendMessage(
  teamId: string,
  input: z.infer<typeof inputSchema>,
): Promise<{messageId: string; status: "sent"}> {
  try {
    const sent = await sendTeamMicrosoftGraphEmail({
      teamId,
      ...input,
      repository: new FirestoreMailConnectorRepository(mailConnectorCipher()),
    });
    logInfo("mail_connector.message_sent", {teamId, connectorId: input.connectorId});
    return {messageId: sent.outboundId, status: "sent"};
  } catch (error) {
    logException("mail_connector.message_send_failed", error, {teamId, connectorId: input.connectorId});
    throw new HttpsError("failed-precondition", "E-Mail konnte nicht gesendet werden.");
  }
}

function inputFrom(data: unknown): z.infer<typeof inputSchema> {
  try {
    return inputSchema.parse(data);
  } catch {
    throw new HttpsError("invalid-argument", "Ungültige E-Mail.");
  }
}
