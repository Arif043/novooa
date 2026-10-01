import {type FileEvent} from "../../../files/domain/entities/file-event.js";
import {fileContentKindOf} from "../../../files/domain/entities/file-content-kind.js";
import {type EventTriggerConfig, type EventTriggerTarget} from "../entities/event-trigger-config.js";

const fileSources: ReadonlySet<string> = new Set(["fileCreated", "fileVersionCreated", "fileDeleted"]);

/** Passt der Kanal bzw. Mail-Connector einer Nachricht zum Ziel des Triggers? */
export function messageTargetMatches(
  target: EventTriggerTarget,
  origin: {channelId: string; connectorId?: string},
): boolean {
  switch (target.kind) {
    case "any": return true;
    case "channel": return origin.connectorId === undefined && target.id === origin.channelId;
    case "connector": return target.id === origin.connectorId;
    default: return false;
  }
}

/**
 * Passt ein Datei-Ereignis zum Trigger? `folderChain` ist das Verzeichnis der
 * Datei samt aller Eltern (leer für die oberste Ebene).
 */
export function fileEventMatches(
  config: EventTriggerConfig,
  event: FileEvent,
  folderChain: readonly string[],
): boolean {
  return config.source === event.type
    && fileTargetMatches(config.target, event, folderChain)
    && kindMatches(config, event)
    && filterMatches(config.filter, event);
}

function fileTargetMatches(
  target: EventTriggerTarget,
  event: FileEvent,
  folderChain: readonly string[],
): boolean {
  switch (target.kind) {
    case "any": return true;
    case "file": return target.id === event.fileId;
    case "folder": return target.includeSubfolders
      ? folderChain.includes(target.id)
      : target.id === event.folderId;
    default: return false;
  }
}

function kindMatches(config: EventTriggerConfig, event: FileEvent): boolean {
  if (config.fileKinds.length === 0) return true;
  return config.fileKinds.includes(fileContentKindOf(event.contentType, event.displayName));
}

function filterMatches(filter: string, event: FileEvent): boolean {
  const expected = filter.trim().toLowerCase();
  return expected.length === 0 || event.displayName.toLowerCase().includes(expected);
}

export function isFileEventSource(source: string): boolean {
  return fileSources.has(source);
}
