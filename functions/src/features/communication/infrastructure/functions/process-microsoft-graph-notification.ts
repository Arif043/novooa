import {onTaskDispatched} from "firebase-functions/v2/tasks";
import {withExceptionLogging} from "../../../../shared/logging/logger.js";
import {
  type GraphNotification,
  processMicrosoftGraphNotification as processNotification,
} from "./microsoft-graph-notification-processor.js";
import {
  mailConnectorEncryptionKey,
  microsoftGraphClientSecret,
} from "../microsoft_graph/microsoft-graph-config.js";

export const processMicrosoftGraphNotification = onTaskDispatched<GraphNotification>(
  {
    region: "europe-west3",
    secrets: [microsoftGraphClientSecret, mailConnectorEncryptionKey],
    retryConfig: {maxAttempts: 5, minBackoffSeconds: 30, maxBackoffSeconds: 600},
    rateLimits: {maxConcurrentDispatches: 10, maxDispatchesPerSecond: 5},
  },
  (request) => withExceptionLogging(
    "microsoft_graph.notification_processing_failed",
    () => processNotification(request.data),
  ),
);
