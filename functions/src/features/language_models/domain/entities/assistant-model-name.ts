/**
 * Name eines Google-Modells für den KI-Agenten, wie ihn die Cloud in Remote
 * Config hinterlegt (etwa `gemini-3.1-flash-lite`). Der Wert ist Fremdeingabe aus
 * einer Konsole: Nur Kleinbuchstaben, Ziffern, Punkt, Bindestrich und
 * Unterstrich sind gültig; alles andere gilt als „nicht gesetzt“, statt als
 * Modellname an die API zu gehen.
 */
const assistantModelNamePattern = /^[a-z0-9][a-z0-9._-]{0,99}$/;

export function assistantModelNameFrom(raw: string): string | null {
  const name = raw.trim();
  return assistantModelNamePattern.test(name) ? name : null;
}
