/** Aufträge und Antworten können lang werden; das Protokoll zeigt einen Auszug. */
export const maximumLoggedCharacters = 2000;

/** `[Teamwork] Task for <Mitarbeiter>` und der Auftrag. */
export function formatDelegationTask(employeeName: string, task: string): string {
  return `[Teamwork] Task for ${employeeName}\n${excerpt(task)}`;
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
