import twilio from "twilio";

export async function sendViaTwilio(input: {
  parentAccountSid: string;
  authToken: string;
  subaccountSid: string;
  sender: string;
  recipient: string;
  body: string;
}): Promise<string> {
  const client = twilio(input.parentAccountSid, input.authToken, {
    accountSid: input.subaccountSid,
  });
  const message = await client.messages.create({
    from: input.sender,
    to: input.recipient,
    body: input.body.trim(),
  });
  return message.sid;
}
