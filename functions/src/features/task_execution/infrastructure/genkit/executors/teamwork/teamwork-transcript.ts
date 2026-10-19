import {type TeamworkConversationEntry} from "../../../../domain/entities/teamwork-conversation.js";
import {type ApplicationLogger} from "../../../../../../shared/logging/application-logger.js";
import {
  formatDelegationAnswer,
  formatDelegationFailure,
  formatDelegationTask,
  formatReviewPassed,
  formatReviewRejected,
} from "./teamwork-log-format.js";
import {type TeamworkTask} from "./teamwork-prompts.js";

/**
 * Hält fest, was in einer Teamarbeit geschieht: Jedes Ereignis wird als Protokollzeile (gekürzt) geschrieben und
 * als Eintrag des Gesprächs (ungekürzt) gesammelt, das die Aktivität des Bausteins zeigt.
 */
export class TeamworkTranscript {
  private readonly recorded: TeamworkConversationEntry[] = [];

  constructor(private readonly logger: ApplicationLogger, private readonly now: () => Date = () => new Date()) {}

  task(memberName: string, {task, expectedResult, boundaries}: TeamworkTask): void {
    this.logger.readableInfo(formatDelegationTask(memberName, {task, expectedResult, boundaries}));
    this.record({kind: "task", memberName, text: task.trim(), expectedResult: expectedResult.trim(),
      ...(boundaries?.trim() ? {boundaries: boundaries.trim()} : {})});
  }

  answer(memberName: string, answer: string, durationMs: number): void {
    this.logger.readableInfo(formatDelegationAnswer(memberName, answer, durationMs));
    this.record({kind: "answer", memberName, text: answer.trim(), durationMs});
  }

  failure(memberName: string, message: string): void {
    this.logger.readableError(formatDelegationFailure(memberName, message));
    this.record({kind: "failure", memberName, text: message});
  }

  review(round: number, verdict: {approved: boolean; findings: string}, final: boolean): void {
    if (verdict.approved) {
      this.logger.readableInfo(formatReviewPassed(round));
    } else {
      this.logger.readableInfo(formatReviewRejected(round, verdict.findings, final));
    }
    this.record({kind: verdict.approved ? "reviewPassed" : "reviewRejected", round, text: verdict.findings.trim()});
  }

  result(fields: Record<string, unknown>): void {
    this.record({kind: "result", text: JSON.stringify(fields, null, 2)});
  }

  entries(): TeamworkConversationEntry[] {
    return [...this.recorded];
  }

  private record(entry: Omit<TeamworkConversationEntry, "occurredAt">): void {
    this.recorded.push({...entry, occurredAt: this.now().toISOString()});
  }
}
