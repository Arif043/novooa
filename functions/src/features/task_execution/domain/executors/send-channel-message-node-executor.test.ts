import assert from "node:assert/strict";
import test from "node:test";
import {type SendTaskMessageInput} from "../repositories/task-message-sender.js";
import {createSendChannelMessageNodeExecutor} from "./send-channel-message-node-executor.js";

test("sends an email reply through the connector from its input event", async () => {
  const sentMessages: SendTaskMessageInput[] = [];

  await execute({
    config: {kind: "email", recipient: "kunde@example.com", subject: "", message: "Danke."},
    input: {event: {type: "emailReceived", connectorId: "connector-1", subject: "Frage"}},
    sentMessages,
  });

  assert.deepEqual(sentMessages, [{
    teamId: "team-1", kind: "email", connectorId: "connector-1",
    recipient: "kunde@example.com", subject: "Re: Frage", body: "Danke.",
  }]);
});

test("rejects an email without an active connector", async () => {
  const sentMessages: SendTaskMessageInput[] = [];

  await assert.rejects(
    execute({
      config: {kind: "email", recipient: "kunde@example.com", subject: "Antwort", message: "Danke."},
      input: {},
      sentMessages,
    }),
    /Verbundenes Postfach fehlt/,
  );

  assert.deepEqual(sentMessages, []);
});

async function execute(input: {
  config: Record<string, string>;
  input: Record<string, unknown>;
  sentMessages: SendTaskMessageInput[];
}) {
  return createSendChannelMessageNodeExecutor().execute(
    {id: "node-1", primitive: "sendChannelMessage", config: input.config} as never,
    {
      teamId: "team-1",
      input: input.input,
      templateExpressionResolver: {resolveText: (value: string) => value},
      messageSender: {
        async send(message: SendTaskMessageInput) {
          input.sentMessages.push(message);
          return {outboundId: "outbound-1", providerMessageId: "provider-1", channelId: "connector-1"};
        },
      },
    } as never,
  );
}
