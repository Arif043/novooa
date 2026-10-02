import {type EventTriggerConfig} from "../entities/event-trigger-config.js";
import {type FileWriteSite} from "../entities/file-write-site.js";

/** `certain`: Das Schreiben löst den Trigger aus, sobald die Stelle läuft. `possible`: nur unter Annahmen. */
export type WriteMatch = "certain" | "possible";

/**
 * Kann eine Schreibstelle den Datei-Trigger auslösen? Statisches Gegenstück zu
 * `fileEventMatches`: Es kennt weder Laufzeitwerte noch Verzweigungen und
 * rechnet deshalb vorsichtig — im Zweifel `possible`, nur sicher
 * Ausgeschlossenes liefert `null`.
 */
export function writeMatch(
  config: EventTriggerConfig,
  site: FileWriteSite,
  folderChainOf: (folderId: string) => readonly string[],
): WriteMatch | null {
  const steps = [
    sourceMatch(config, site),
    targetMatch(config, site, folderChainOf),
    kindMatch(config, site),
    filterMatch(config, site),
  ];
  if (steps.includes(null)) return null;
  return steps.includes("possible") ? "possible" : "certain";
}

function sourceMatch(config: EventTriggerConfig, site: FileWriteSite): WriteMatch | null {
  const isNewFileSite = site.placement.kind === "folder";
  if (config.source === "fileCreated") return isNewFileSite ? "certain" : null;
  if (config.source !== "fileVersionCreated") return null;
  if (!isNewFileSite) return "certain";
  // Nur in der obersten Ebene wird ein gleichnamiges Objekt zur neuen Version.
  return site.placement.kind === "folder" && site.placement.folderId === null ? "possible" : null;
}

function targetMatch(
  config: EventTriggerConfig,
  site: FileWriteSite,
  folderChainOf: (folderId: string) => readonly string[],
): WriteMatch | null {
  const target = config.target;
  switch (target.kind) {
    case "any": return "certain";
    case "folder": return folderMatch(target, site, folderChainOf);
    case "file": return fileMatch(target, site);
    default: return null;
  }
}

function folderMatch(
  target: {id: string; includeSubfolders: boolean},
  site: FileWriteSite,
  folderChainOf: (folderId: string) => readonly string[],
): WriteMatch | null {
  // Das Verzeichnis einer bestehenden Datei steht erst zur Laufzeit fest.
  if (site.placement.kind === "existingFile") return "possible";
  const folderId = site.placement.folderId;
  if (folderId === null) return null;
  const inside = target.includeSubfolders ? folderChainOf(folderId).includes(target.id) : folderId === target.id;
  return inside ? "certain" : null;
}

function fileMatch(target: {id: string; label: string}, site: FileWriteSite): WriteMatch | null {
  if (site.placement.kind === "existingFile") return site.placement.fileId === target.id ? "certain" : null;
  const sameName = site.fileName !== null && site.fileName === target.label;
  return site.placement.folderId === null && sameName ? "possible" : null;
}

function kindMatch(config: EventTriggerConfig, site: FileWriteSite): WriteMatch | null {
  if (config.fileKinds.length === 0 || site.contentKind === null) return "certain";
  if (config.fileKinds.includes(site.contentKind)) return site.contentKindIsCertain ? "certain" : "possible";
  return site.contentKindIsCertain ? null : "possible";
}

function filterMatch(config: EventTriggerConfig, site: FileWriteSite): WriteMatch | null {
  const filter = config.filter.trim().toLowerCase();
  if (filter.length === 0) return "certain";
  if (site.fileName === null || site.fileName.includes("{{")) return "possible";
  return site.fileName.toLowerCase().includes(filter) ? "certain" : null;
}
