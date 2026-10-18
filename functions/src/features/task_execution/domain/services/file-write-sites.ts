import {type FileWriteSite} from "../../../scheduling/domain/entities/file-write-site.js";
import {fileContentKindOf} from "../../../files/domain/entities/file-content-kind.js";
import {type TaskDefinition} from "../entities/task.js";
import {allNodesOf, type GraphNode, record} from "./task-graph-nodes.js";

/**
 * Alle Stellen, an denen eine Aufgabe Dateien schreiben kann — auch in
 * Verzweigungen und Schleifen. Welche davon wirklich laufen, entscheidet erst
 * die Ausführung; die Analyse rechnet deshalb mit allen.
 */
export function fileWriteSitesOf(task: Pick<TaskDefinition, "nodes">): FileWriteSite[] {
  return allNodesOf(task).flatMap(siteOf);
}

function siteOf(node: GraphNode): FileWriteSite[] {
  const config = record(node.config);
  if (config.primitive === "writeFile") return [writeFileSite(config)];
  if (config.primitive === "prompt" && config.outputType === "image") {
    return [{
      placement: {kind: "folder", folderId: null},
      fileName: `generiertes-bild-${node.id}`, contentKind: "image", contentKindIsCertain: true,
    }];
  }
  if (isSpeechNode(config.primitive)) {
    return [{
      placement: {kind: "folder", folderId: null},
      fileName: null, contentKind: "audio", contentKindIsCertain: true,
    }];
  }
  return [];
}

function writeFileSite(config: Record<string, unknown>): FileWriteSite {
  const fileName = text(config.fileName);
  const contentType = text(config.contentType) ?? "text/plain";
  const fileId = text(config.fileId);
  return {
    placement: fileId === null
      ? {kind: "folder", folderId: text(config.folderId)}
      : {kind: "existingFile", fileId},
    fileName,
    contentKind: fileContentKindOf(contentType, fileName ?? ""),
    contentKindIsCertain: false,
  };
}

function isSpeechNode(primitive: unknown): boolean {
  return primitive === "textToSpeech";
}

function text(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : null;
}
