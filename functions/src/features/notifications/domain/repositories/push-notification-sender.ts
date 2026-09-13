import {type PushNotification} from "../entities/push-notification.js";

export interface PushNotificationSender {
  sendToRecipient(
    recipientId: string,
    notification: PushNotification,
  ): Promise<void>;
}
