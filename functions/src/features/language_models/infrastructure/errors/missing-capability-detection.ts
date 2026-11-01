/**
 * Erkennt in der Ablehnung eines Anbieters, welche Fähigkeit dem Modell fehlt. novooa prüft Fähigkeiten
 * nicht vorab, sondern nimmt an, dass ein Modell kann, was verlangt wird; lehnt der Anbieter ab, wird
 * daraus ein verständlicher Geschäftsfehler statt einer rohen Anbietermeldung.
 */
const capabilityPatterns: ReadonlyArray<readonly [capability: string, pattern: RegExp]> = [
  ["Werkzeugaufrufe", /does not support tools|(?:tool|function)[ _-]?(?:use|calls?|calling)\b[^.]{0,40}\b(?:not (?:supported|enabled|available)|unsupported)|tool_choice[^.]{0,40}not supported/i],
  ["strukturierte Ausgabe", /(?:response_format|json_schema|structured output|response mime type)[^.]{0,40}\b(?:not supported|unsupported)/i],
  ["Bildgenerierung", /(?:image generation|image output|response modalit(?:y|ies)|output modalit(?:y|ies))[^.]{0,40}\b(?:not supported|unsupported)/i],
  ["Bildeingaben", /does not support (?:images?|vision|image input)|(?:image[ _-]?(?:input|inputs|content|url)|vision|multimodal input)[^.]{0,40}\b(?:not supported|unsupported)/i],
  ["den Denkmodus", /does not support think(?:ing)?/i],
];

/** Die fehlende Fähigkeit in deutscher Form, z. B. „Werkzeugaufrufe“; `undefined`, wenn der Fehler keine nennt. */
export function missingCapabilityIn(error: unknown): string | undefined {
  const text = messagesOf(error).join("\n");
  return capabilityPatterns.find(([, pattern]) => pattern.test(text))?.[0];
}

/** Meldung und Ursachen, damit auch eine schon übersetzte Ablehnung erkannt wird. */
function messagesOf(error: unknown, depth = 0): string[] {
  if (!(error instanceof Error) || depth > 3) return [];
  const {originalError, cause} = error as {originalError?: unknown; cause?: unknown};
  return [error.message, ...messagesOf(originalError ?? cause, depth + 1)];
}
