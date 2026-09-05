/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions/v2";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({region: "europe-west3", maxInstances: 10});

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

export {
  reviewTaskRun,
  runTaskDefinitionFlow,
  runTaskRunTask,
} from "./features/task_execution/infrastructure/firebase/task-workflow-functions.js";

export {runDueTaskTriggersWorker} from "./features/scheduling/infrastructure/functions/schedule-workflows.js";
export {askKnowledgeBaseAssistant} from "./features/knowledge_base/infrastructure/functions/knowledge-base-assistant-workflows.js";
export {askTaskBuilderAssistant} from "./features/task_execution/infrastructure/functions/task-builder-assistant-workflows.js";
export {twilioWebhook} from "./features/communication/infrastructure/twilio/twilio-webhook.js";
export {dispatchFakeChannelMessage} from "./features/communication/infrastructure/functions/fake-channel-message.js";
export {sendChannelMessage} from "./features/communication/infrastructure/functions/send-channel-message.js";
export {beginMicrosoftMailConnector} from "./features/communication/infrastructure/functions/begin-microsoft-mail-connector.js";
export {completeMicrosoftMailConnector} from "./features/communication/infrastructure/functions/complete-microsoft-mail-connector.js";
export {microsoftGraphWebhook} from "./features/communication/infrastructure/functions/microsoft-graph-webhook.js";
export {processMicrosoftGraphNotification} from "./features/communication/infrastructure/functions/process-microsoft-graph-notification.js";
export {renewMicrosoftMailSubscriptions} from "./features/communication/infrastructure/functions/renew-microsoft-mail-subscriptions.js";
export {sendMicrosoftMailConnectorMessage} from "./features/communication/infrastructure/functions/send-microsoft-mail-connector-message.js";
export {
  acceptTeamInvitationFlow,
  addTeamMemberFlow,
  rejectTeamInvitationFlow,
  removeTeamMemberFlow,
} from "./features/teams/infrastructure/functions/team-workflows.js";
