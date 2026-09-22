import {type PushNotification} from "../entities/push-notification.js";

/**
 * Sendet eine Push-Benachrichtigung an alle Nutzer:innen eines Teams.
 *
 * Cloud und lokale Runtime lösen "alle Nutzer:innen des Teams" unterschiedlich
 * auf: Firebase kennt einzelne Mitglieder-UIDs, die lokale Runtime kennt nur
 * die Geräte der aktiven Lizenz (ein Team = ein Arbeitsbereich).
 */
export interface TeamNotificationSender {
  sendToTeam(teamId: string, notification: PushNotification): Promise<void>;
}
