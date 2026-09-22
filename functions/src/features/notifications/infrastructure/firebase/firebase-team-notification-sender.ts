import {type PushNotification} from "../../domain/entities/push-notification.js";
import {type PushNotificationSender} from "../../domain/repositories/push-notification-sender.js";
import {type TeamNotificationSender} from "../../domain/repositories/team-notification-sender.js";
import {type TeamMembershipStore} from "../../../teams/domain/repositories/team-membership-store.js";
import {FirestoreTeamMembershipStore} from "../../../teams/infrastructure/firebase/firestore-team-membership-store.js";
import {FirebasePushNotificationSender} from "./firebase-push-notification-sender.js";

export class FirebaseTeamNotificationSender implements TeamNotificationSender {
  constructor(
    private readonly membershipStore: TeamMembershipStore = new FirestoreTeamMembershipStore(),
    private readonly pushSender: PushNotificationSender = new FirebasePushNotificationSender(),
  ) {}

  async sendToTeam(teamId: string, notification: PushNotification): Promise<void> {
    const uids = await this.membershipStore.memberUids(teamId);
    await Promise.all(
      uids.map((uid) => this.pushSender.sendToRecipient(uid, notification)),
    );
  }
}
