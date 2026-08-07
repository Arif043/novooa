export type ConnectorMailMessage = {
  id: string;
  senderEmail: string;
  recipientEmail: string;
  subject: string;
  body: string;
  receivedAt: Date;
};
