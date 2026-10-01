export const fileContentKinds = [
  "text", "image", "video", "audio", "pdf", "spreadsheet", "other",
] as const;

export type FileContentKind = (typeof fileContentKinds)[number];

const spreadsheetContentType =
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

/**
 * Ordnet einen MIME-Type einer Anzeige-Kategorie zu — dieselbe Einteilung wie
 * der Flutter-Client (`FileContentKindClassifier`), ergänzt um Video und
 * Audio. Der Dateiname dient als Rückfall für generische Binärtypen.
 */
export function fileContentKindOf(contentType: string, fileName = ""): FileContentKind {
  const type = contentType.trim().toLowerCase();
  if (type.startsWith("text/") || type === "application/json") return "text";
  if (type.startsWith("image/")) return "image";
  if (type.startsWith("video/")) return "video";
  if (type.startsWith("audio/")) return "audio";
  if (type === "application/pdf") return "pdf";
  if (type === spreadsheetContentType) return "spreadsheet";
  const isGeneric = type === "" || type === "application/octet-stream";
  if (isGeneric && fileName.toLowerCase().endsWith(".xlsx")) return "spreadsheet";
  return "other";
}
