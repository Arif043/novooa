import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {
  type ApprovalNotificationInput,
  type MarkApprovalNotificationInput,
  type TaskRunApprovalNotificationStore,
} from "../../domain/repositories/task-run-approval-notification-store.js";
import {type RuntimePushRelayClient} from "./runtime-push-relay-client.js";

export class LocalTaskRunApprovalPushNotifier
implements TaskRunApprovalNotificationStore {
  constructor(
    private readonly signedLicense: () => SignedRuntimeLicense | null,
    private readonly relay: RuntimePushRelayClient,
    private readonly logger: ApplicationLogger,
  ) {}

  async notifyApprovalRequired(input: ApprovalNotificationInput): Promise<void> {
    const license = this.signedLicense();
    if (license === null) return;
    try {
      await this.relay.send(license, {
        title: notificationTitle(input),
        body: `"${input.run.taskTitle}" wartet auf deine Eingabe.`,
        data: {type: "taskRunApproval", runId: input.run.runId},
      });
    } catch (error) {
      this.logger.exception("local_runtime_push.send_failed", error, {
        runId: input.run.runId,
        teamId: input.teamId,
      });
    }
  }

  async markApprovalNotifications(_input: MarkApprovalNotificationInput): Promise<void> {}
}

function notificationTitle(input: ApprovalNotificationInput): string {
  return input.review.interaction.kind === "approval"
    ? "Freigabe erforderlich"
    : "Eingabe erforderlich";
}
