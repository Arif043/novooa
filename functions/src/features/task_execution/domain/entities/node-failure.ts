/**
 * Warum ein Baustein gescheitert ist, als Wert: ein stabiler Code, den der
 * Client übersetzt, ein sprachneutraler technischer Text und die Felder für
 * die Übersetzung (z. B. Operator und erhaltener Wert).
 */
export class NodeFailure {
  private constructor(
    readonly code: string,
    readonly message: string,
    readonly details: Readonly<Record<string, string>>,
  ) {}

  static of(input: {code: string; message: string; details?: Record<string, string>}): NodeFailure {
    return new NodeFailure(input.code, input.message, {...(input.details ?? {})});
  }
}
