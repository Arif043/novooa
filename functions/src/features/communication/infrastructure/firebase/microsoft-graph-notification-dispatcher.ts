import {getFunctions} from "firebase-admin/functions";
import {type GraphNotification} from "./microsoft-graph-notification-processor.js";
import {initializeAdminApp} from "../../../../shared/firebase/firestore-db.js";

const queueFunction = "locations/europe-west3/functions/processMicrosoftGraphNotification";

export async function dispatchMicrosoftGraphNotification(
  notification: GraphNotification,
): Promise<void> {
  initializeAdminApp();
  await getFunctions().taskQueue(queueFunction).enqueue(notification);
}
