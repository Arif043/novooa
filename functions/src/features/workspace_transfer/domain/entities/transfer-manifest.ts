import {isTransferCategory, type TransferCategory, type TransferCounts} from "./transfer-category.js";
import {InvalidTransferArchiveError} from "./transfer-errors.js";

export const transferFormat = "novooa-export";
export const transferFormatVersion = 2;
export const transferManifestEntry = "manifest.json";

export type TransferManifest = {
  format: typeof transferFormat;
  version: typeof transferFormatVersion;
  exportedAt: string;
  /** Für das Umschreiben team-gebundener Speicherpfade beim Import. */
  sourceTeamId: string;
  categories: TransferCategory[];
  counts: TransferCounts;
};

export function createTransferManifest(input: {
  sourceTeamId: string; counts: TransferCounts; exportedAt: Date;
}): TransferManifest {
  return {
    format: transferFormat,
    version: transferFormatVersion,
    exportedAt: input.exportedAt.toISOString(),
    sourceTeamId: input.sourceTeamId,
    categories: Object.keys(input.counts).filter(isTransferCategory),
    counts: input.counts,
  };
}

export function transferManifestFrom(value: unknown): TransferManifest {
  if (!isRecord(value) || value.format !== transferFormat) {
    throw new InvalidTransferArchiveError("Die Datei ist kein novooa-Export.");
  }
  if (value.version !== transferFormatVersion) {
    throw new InvalidTransferArchiveError("Diese Export-Version wird nicht unterstützt.");
  }
  return {
    format: transferFormat,
    version: transferFormatVersion,
    exportedAt: requiredText(value.exportedAt),
    sourceTeamId: requiredText(value.sourceTeamId),
    categories: categoriesFrom(value.categories),
    counts: countsFrom(value.counts),
  };
}

function categoriesFrom(value: unknown): TransferCategory[] {
  if (!Array.isArray(value) || !value.every(isTransferCategory)) {
    throw new InvalidTransferArchiveError("Der Export enthält unbekannte Bereiche.");
  }
  return value;
}

function countsFrom(value: unknown): TransferCounts {
  if (!isRecord(value)) throw new InvalidTransferArchiveError("Die Mengenangaben des Exports fehlen.");
  const counts: TransferCounts = {};
  for (const [key, count] of Object.entries(value)) {
    if (!isTransferCategory(key) || !Number.isSafeInteger(count) || (count as number) < 0) {
      throw new InvalidTransferArchiveError("Die Mengenangaben des Exports sind ungültig.");
    }
    counts[key] = count as number;
  }
  return counts;
}

function requiredText(value: unknown): string {
  if (typeof value === "string" && value.trim().length > 0) return value;
  throw new InvalidTransferArchiveError("Das Manifest des Exports ist unvollständig.");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
