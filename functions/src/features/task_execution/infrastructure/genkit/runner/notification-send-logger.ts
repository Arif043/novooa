import {
  type NotificationSendFailed,
  type NotificationSendObserver,
  type NotificationSendSent,
} from "../../../domain/executors/notification-send-node-executor.js";
import {errorDetails, textSummary} from "./structured-logger.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

export function notificationSendLogger(logger: ApplicationLogger): NotificationSendObserver {
  return {
    sent: (event) => logNotificationSent(logger, event),
    failed: (event) => logNotificationFailed(logger, event),
  };
}

function logNotificationSent(logger: ApplicationLogger, event: NotificationSendSent): void {
  logger.info("notification_send_node.sent", {
    teamId: event.teamId,
    title: event.title,
    ...textSummary(event.body, "message"),
  });
}

function logNotificationFailed(logger: ApplicationLogger, event: NotificationSendFailed): void {
  logger.error("notification_send_node.failed", {
    teamId: event.teamId,
    error: errorDetails(event.error),
  });
}
