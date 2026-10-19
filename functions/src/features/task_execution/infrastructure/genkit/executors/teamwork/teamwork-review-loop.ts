import {type TeamworkVerdict} from "./teamwork-review.js";
import {maximumRevisions} from "./teamwork-review-prompts.js";
import {type TeamworkTranscript} from "./teamwork-transcript.js";

/** Ein Ergebnis des Orchestrators, das er nach einer Beanstandung im selben Gespräch überarbeiten kann. */
export type OrchestrationRound = {
  fields: Record<string, unknown>;
  revise(findings: string): Promise<OrchestrationRound>;
};

export type ReviewStep = (fields: Record<string, unknown>, round: number) => Promise<TeamworkVerdict>;

/**
 * Prüft das Ergebnis und lässt es bei Beanstandung höchstens `maximumRevisions`-mal überarbeiten. Bleibt es
 * danach beanstandet, wird es trotzdem geliefert: Der Lauf soll nicht an einer strengen Prüfung scheitern;
 * die offenen Punkte stehen im Protokoll und im Gespräch.
 */
export async function reviewedFields(
  first: OrchestrationRound, review: ReviewStep, transcript: TeamworkTranscript,
): Promise<Record<string, unknown>> {
  let current = first;
  for (let round = 1; ; round += 1) {
    const verdict = await review(current.fields, round);
    const final = round > maximumRevisions;
    transcript.review(round, verdict, final);
    if (verdict.approved || final) return current.fields;
    current = await current.revise(verdict.findings);
  }
}
