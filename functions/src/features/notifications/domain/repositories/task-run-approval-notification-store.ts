import {type WaitingTaskGraphOutput} from "../../../task_execution/domain/entities/task.js";
import {type DialogInputDefinition} from "../../../task_execution/domain/entities/dialog-input.js";
import {type TaskRunDocument} from "../../../task_execution/domain/repositories/task-run-store.js";

export type TaskRunApprovalReview = {
  instruction: string;
  output: string;
  dialogInput?: DialogInputDefinition;
};

export type ApprovalNotificationStatus = "accepted" | "rejected";

export type ApprovalNotificationInput = {
  teamId: string;
  run: TaskRunDocument;
  output: WaitingTaskGraphOutput;
  review: TaskRunApprovalReview;
};

export type MarkApprovalNotificationInput = {
  teamId: string;
  runId: string;
  status: ApprovalNotificationStatus;
};

export interface TaskRunApprovalNotificationStore {
  notifyApprovalRequired(input: ApprovalNotificationInput): Promise<void>;
  markApprovalNotifications(
    input: MarkApprovalNotificationInput,
  ): Promise<void>;
}
