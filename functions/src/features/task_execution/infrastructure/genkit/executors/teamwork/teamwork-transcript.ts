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

/** Der Mitarbeiter, der einen Auftrag bekommt oder antwortet. */
export type TranscriptMember = {id: string; name: string};

/**
 * Hält fest, was in einer Teamarbeit geschieht: Jedes Ereignis wird als Protokollzeile (gekürzt) geschrieben und
 * als Eintrag des Gesprächs (ungekürzt) gesammelt, das die Aktivität des Bausteins zeigt.
 */
export class TeamworkTranscript {
  private readonly recorded: TeamworkConversationEntry[] = [];

  constructor(private readonly logger: ApplicationLogger, private readonly now: () => Date = () => new Date()) {}

  task(member: TranscriptMember, {task, expectedResult, boundaries}: TeamworkTask): void {
    this.logger.readableInfo(formatDelegationTask(member.name, {task, expectedResult, boundaries}));
    this.record({kind: "task", ...memberOf(member), text: task.trim(), expectedResult: expectedResult.trim(),
      ...(boundaries?.trim() ? {boundaries: boundaries.trim()} : {})});
  }

  answer(member: TranscriptMember, answer: string, durationMs: number): void {
    this.logger.readableInfo(formatDelegationAnswer(member.name, answer, durationMs));
    this.record({kind: "answer", ...memberOf(member), text: answer.trim(), durationMs});
  }

  failure(member: TranscriptMember, message: string): void {
    this.logger.readableError(formatDelegationFailure(member.name, message));
    this.record({kind: "failure", ...memberOf(member), text: message});
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

function memberOf(member: TranscriptMember): Pick<TeamworkConversationEntry, "memberId" | "memberName"> {
  return {memberId: member.id, memberName: member.name};
}
