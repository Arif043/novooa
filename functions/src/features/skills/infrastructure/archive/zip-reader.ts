import {unzipSync} from "fflate";
import {SkillImportError} from "../../domain/entities/skill-import-error.js";
import {type SkillFile} from "../../domain/entities/skill-package.js";

export const archiveLimits = {
  /** Einzelne Datei im Archiv; größere werden übersprungen (ein Skill braucht sie nicht). */
  maximumEntryBytes: 5 * 1024 * 1024,
  /** Entpackte Gesamtgröße — schützt vor Zip-Bomben. */
  maximumTotalBytes: 100 * 1024 * 1024,
  maximumEntries: 20_000,
} as const;

/** Entpackt ein ZIP im Speicher. Verzeichnisse und zu große Einzeldateien entfallen. */
export function readZipFiles(bytes: Uint8Array): SkillFile[] {
  let entries = 0;
  let total = 0;
  try {
    const unpacked = unzipSync(bytes, {
      filter: (file) => {
        if (file.name.endsWith("/")) return false;
        if (++entries > archiveLimits.maximumEntries) throw new SkillImportError("Das Archiv enthält zu viele Dateien.");
        if (file.originalSize > archiveLimits.maximumEntryBytes) return false;
        total += file.originalSize;
        if (total > archiveLimits.maximumTotalBytes) throw new SkillImportError("Das Archiv ist entpackt zu groß.");
        return true;
      },
    });
    return Object.entries(unpacked).map(([path, content]) => ({path: path.replace(/\\/g, "/"), bytes: content}));
  } catch (error) {
    if (error instanceof SkillImportError) throw error;
    throw new SkillImportError("Die Datei ist kein gültiges ZIP-Archiv.");
  }
}

/**
 * Archive haben oft einen gemeinsamen Wurzelordner (`repo-main/…`, `mein-skill/…`). Er wird abgeschnitten und
 * als Name zurückgegeben; liegen Dateien direkt an der Wurzel, bleibt alles unverändert.
 */
export function withoutCommonRoot(files: readonly SkillFile[]): {files: SkillFile[]; root?: string} {
  const first = files[0]?.path.split("/")[0];
  const shared = first !== undefined && files.every((file) => file.path.includes("/") && file.path.split("/")[0] === first);
  if (!shared) return {files: [...files]};
  return {files: files.map((file) => ({path: file.path.slice(first.length + 1), bytes: file.bytes})), root: first};
}
