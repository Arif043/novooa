import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {type PushNotification} from "../../domain/entities/push-notification.js";
import {type TeamNotificationSender} from "../../domain/repositories/team-notification-sender.js";
import {type RuntimePushRelayClient} from "./runtime-push-relay-client.js";

/**
 * Die lokale Runtime kennt keine einzelnen Mitglieder-UIDs, sondern nur die
 * beim Push-Relay registrierten Geräte der aktiven Lizenz. Ein Team
 * entspricht hier genau einem Arbeitsbereich, daher sendet dieser Adapter
 * einmalig über den Relay statt Empfänger einzeln aufzulösen.
 */
export class LocalTeamNotificationSender implements TeamNotificationSender {
  constructor(
    private readonly signedLicense: () => SignedRuntimeLicense | null,
    private readonly relay: RuntimePushRelayClient,
    private readonly logger: ApplicationLogger,
  ) {}

  async sendToTeam(teamId: string, notification: PushNotification): Promise<void> {
    const license = this.signedLicense();
    if (license === null) return;
    try {
      await this.relay.send(license, notification);
    } catch (error) {
      this.logger.exception("local_team_notification.send_failed", error, {teamId});
    }
  }
}
