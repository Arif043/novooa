/**
 * Spiegelt den Modellnamen des KI-Agenten aus Remote Config in das Dokument,
 * auf das die lokalen Runtimes hören. Schreibt nur bei einer echten
 * Änderung: Jede Veröffentlichung in Remote Config löst den Abgleich aus,
 * auch wenn ein ganz anderer Parameter geändert wurde — die Runtimes sollen
 * dann nicht geweckt werden.
 */
export type SyncAssistantModelConfigPorts = {
  /** Der aktuelle Name aus Remote Config (frisch gelesen, nicht gecacht). */
  readCurrent: () => Promise<string | null>;
  /** Der Name, der zuletzt veröffentlicht wurde, oder `undefined` ohne Dokument. */
  readPublished: () => Promise<string | null | undefined>;
  publish: (name: string | null) => Promise<void>;
};

export async function syncAssistantModelConfig(
  ports: SyncAssistantModelConfigPorts,
): Promise<"published" | "unchanged"> {
  const current = await ports.readCurrent();
  const published = await ports.readPublished();
  if (published === current) return "unchanged";
  await ports.publish(current);
  return "published";
}
