import {
  type TaskMessageFailed,
  type TaskMessageObserver,
  type TaskMessageSent,
  type TaskMessageStarted,
} from "../../../domain/executors/send-channel-message-node-executor.js";
import {
  errorDetails,
  nodeSummary,
  textSummary,
} from "./structured-logger.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

export function taskMessageLogger(logger: ApplicationLogger): TaskMessageObserver {
  return {
    started: (event) => logMessageStarted(logger, event),
    sent: (event) => logMessageSent(logger, event),
    failed: (event) => logMessageFailed(logger, event),
  };
}

function logMessageStarted(logger: ApplicationLogger, event: TaskMessageStarted): void {
  logger.info("send_channel_node.started", {
    teamId: event.teamId,
    ...nodeSummary(event.node),
    kind: event.kind,
    recipientLength: event.recipient.length,
    ...textSummary(event.body, "message"),
  });
}

function logMessageSent(logger: ApplicationLogger, event: TaskMessageSent): void {
  logger.info("send_channel_node.sent", {
    teamId: event.teamId,
    ...nodeSummary(event.node),
    kind: event.kind,
    channelId: event.channelId,
    outboundId: event.outboundId,
    providerMessageId: event.providerMessageId,
  });
}

function logMessageFailed(logger: ApplicationLogger, event: TaskMessageFailed): void {
  logger.error("send_channel_node.failed", {
    teamId: event.teamId,
    kind: event.kind,
    error: errorDetails(event.error),
  });
}
