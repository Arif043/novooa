export const DEFAULT_FILE_VERSION_LIMIT = 10;

export type RotatableFileVersion = {
  id: string;
  createdAt: number;
};

/**
 * Die aktuelle Version bleibt immer erhalten, auch wenn mehrere Versionen
 * denselben Zeitstempel tragen (SQLite speichert nur Sekunden).
 */
export function versionsToRotateOut<T extends RotatableFileVersion>(
  versions: readonly T[],
  limit: number,
  currentVersionId: string,
): T[] {
  const current = versions.filter((version) => version.id === currentVersionId);
  const others = versions
    .filter((version) => version.id !== currentVersionId)
    .sort((left, right) => right.createdAt - left.createdAt);
  return [...current, ...others].slice(Math.max(limit, 1));
}

export function parseFileVersionLimit(raw: string | undefined): number {
  const trimmed = raw?.trim();
  if (!trimmed) return DEFAULT_FILE_VERSION_LIMIT;
  const value = Number(trimmed);
  if (Number.isSafeInteger(value) && value >= 1) return value;
  throw new Error(
    "Das Versionslimit für Dateien muss eine ganze Zahl ab 1 sein.",
  );
}
