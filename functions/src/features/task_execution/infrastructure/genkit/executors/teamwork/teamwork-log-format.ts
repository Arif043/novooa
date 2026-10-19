import {type TeamworkTask} from "./teamwork-prompts.js";

/** Aufträge und Antworten können lang werden; das Protokoll zeigt einen Auszug. */
export const maximumLoggedCharacters = 2000;

/** `[Teamwork] Task for <Mitarbeiter>` und der Auftrag mit erwartetem Ergebnis und Grenzen. */
export function formatDelegationTask(employeeName: string, {task, expectedResult, boundaries}: TeamworkTask): string {
  const parts = [`Task: ${task.trim()}`, `Expected result: ${expectedResult.trim()}`];
  if (boundaries?.trim()) parts.push(`Boundaries: ${boundaries.trim()}`);
  return `[Teamwork] Task for ${employeeName}\n${excerpt(parts.join("\n"))}`;
}

/** `[Teamwork] Answer from <Mitarbeiter> (<Dauer>)` und die Antwort. */
export function formatDelegationAnswer(employeeName: string, answer: string, durationMs: number): string {
  return `[Teamwork] Answer from ${employeeName} (${(durationMs / 1000).toFixed(1)} s)\n${excerpt(answer)}`;
}

export function formatDelegationFailure(employeeName: string, message: string): string {
  return `[Teamwork] Task for ${employeeName} failed\n${excerpt(message)}`;
}

function excerpt(text: string): string {
  const trimmed = text.trim();
  if (trimmed.length <= maximumLoggedCharacters) return trimmed;
  return `${trimmed.slice(0, maximumLoggedCharacters)}\n… (${trimmed.length - maximumLoggedCharacters} weitere Zeichen)`;
}

/** `[Teamwork] Review <n> passed`. */
export function formatReviewPassed(round: number): string {
  return `[Teamwork] Review ${round} passed`;
}

/** `[Teamwork] Review <n> rejected` und der Befund; nach der letzten Runde mit Hinweis, dass trotzdem abgegeben wird. */
export function formatReviewRejected(round: number, findings: string, final: boolean): string {
  const note = final ? " – no revisions left, result delivered with open findings" : "";
  return `[Teamwork] Review ${round} rejected${note}\n${excerpt(findings)}`;
}
