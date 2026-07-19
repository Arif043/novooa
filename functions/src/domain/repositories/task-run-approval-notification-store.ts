import {type WaitingTaskGraphOutput} from "../entities/task.js";
import {type TaskRunDocument} from "./task-run-store.js";

export type TaskRunApprovalReview = {
  instruction: string;
  output: string;
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
