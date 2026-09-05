import {
  type TaskMessageFailed,
  type TaskMessageObserver,
  type TaskMessageSent,
  type TaskMessageStarted,
} from "../../../domain/executors/send-channel-message-node-executor.js";
import {
  errorDetails,
  logError,
  logInfo,
  nodeSummary,
  textSummary,
} from "./structured-logger.js";

export const taskMessageLogger: TaskMessageObserver = {
  started: logMessageStarted,
  sent: logMessageSent,
  failed: logMessageFailed,
};

function logMessageStarted(event: TaskMessageStarted): void {
  logInfo("send_channel_node.started", {
    teamId: event.teamId,
    ...nodeSummary(event.node),
    kind: event.kind,
    recipientLength: event.recipient.length,
    ...textSummary(event.body, "message"),
  });
}

function logMessageSent(event: TaskMessageSent): void {
  logInfo("send_channel_node.sent", {
    teamId: event.teamId,
    ...nodeSummary(event.node),
    kind: event.kind,
    channelId: event.channelId,
    outboundId: event.outboundId,
    providerMessageId: event.providerMessageId,
  });
}

function logMessageFailed(event: TaskMessageFailed): void {
  logError("send_channel_node.failed", {
    teamId: event.teamId,
    kind: event.kind,
    error: errorDetails(event.error),
  });
}
