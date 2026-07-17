import {request} from "https";

export async function sendViaSendgrid(input: {
  apiKey: string;
  sender: string;
  recipient: string;
  subject: string;
  body: string;
}): Promise<string> {
  const response = await postJson(input.apiKey, {
    personalizations: [{to: [{email: input.recipient}]}],
    from: {email: input.sender},
    subject: input.subject,
    content: [{type: "text/plain", value: input.body}],
  });
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw new Error(`SendGrid failed with status ${response.statusCode}.`);
  }
  return response.messageId || `sendgrid-${Date.now()}`;
}

function postJson(
  apiKey: string,
  payload: Record<string, unknown>,
): Promise<{statusCode: number; messageId: string}> {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(payload);
    const req = request({
      hostname: "api.sendgrid.com",
      path: "/v3/mail/send",
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    }, (res) => {
      res.resume();
      res.on("end", () => resolve({
        statusCode: res.statusCode ?? 0,
        messageId: String(res.headers["x-message-id"] ?? ""),
      }));
    });
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}
