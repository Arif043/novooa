/**
 * Das erste JSON-Objekt in einer Modellantwort, auch in Codezäunen oder mit Text davor;
 * `undefined`, wenn keins lesbar ist. Für den Rückweg, wenn ein Modell das Ausgabeschema verfehlt.
 */
export function jsonFromText(text: string): unknown {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end <= start) return undefined;
  try {
    return JSON.parse(text.slice(start, end + 1));
  } catch {
    return undefined;
  }
}
