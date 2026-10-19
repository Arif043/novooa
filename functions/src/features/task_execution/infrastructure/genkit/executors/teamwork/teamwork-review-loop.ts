import {type ApplicationLogger} from "../../../../../../shared/logging/application-logger.js";
import {formatReviewPassed, formatReviewRejected} from "./teamwork-log-format.js";
import {type TeamworkVerdict} from "./teamwork-review.js";
import {maximumRevisions} from "./teamwork-review-prompts.js";

/** Ein Ergebnis des Orchestrators, das er nach einer Beanstandung im selben Gespräch überarbeiten kann. */
export type OrchestrationRound = {
  fields: Record<string, unknown>;
  revise(findings: string): Promise<OrchestrationRound>;
};

export type ReviewStep = (fields: Record<string, unknown>, round: number) => Promise<TeamworkVerdict>;

/**
 * Prüft das Ergebnis und lässt es bei Beanstandung höchstens `maximumRevisions`-mal überarbeiten. Bleibt es
 * danach beanstandet, wird es trotzdem geliefert: Der Lauf soll nicht an einer strengen Prüfung scheitern;
 * die offenen Punkte stehen im Protokoll.
 */
export async function reviewedFields(
  first: OrchestrationRound, review: ReviewStep, logger: ApplicationLogger,
): Promise<Record<string, unknown>> {
  let current = first;
  for (let round = 1; ; round += 1) {
    const verdict = await review(current.fields, round);
    if (verdict.approved) {
      logger.readableInfo(formatReviewPassed(round));
      return current.fields;
    }
    const final = round > maximumRevisions;
    logger.readableInfo(formatReviewRejected(round, verdict.findings, final));
    if (final) return current.fields;
    current = await current.revise(verdict.findings);
  }
}
