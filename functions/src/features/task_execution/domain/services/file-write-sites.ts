import {type FileWriteSite} from "../../../scheduling/domain/entities/file-write-site.js";
import {fileContentKindOf} from "../../../files/domain/entities/file-content-kind.js";
import {type BranchWorkflowGraph, type TaskDefinition} from "../entities/task.js";

type GraphNode = {id: string; primitive: string; config?: unknown};

/**
 * Alle Stellen, an denen eine Aufgabe Dateien schreiben kann — auch in
 * Verzweigungen und Schleifen. Welche davon wirklich laufen, entscheidet erst
 * die Ausführung; die Analyse rechnet deshalb mit allen.
 */
export function fileWriteSitesOf(task: Pick<TaskDefinition, "nodes">): FileWriteSite[] {
  return nodesOf(task).flatMap(siteOf);
}

function nodesOf(graph: {nodes: readonly GraphNode[]}): GraphNode[] {
  return graph.nodes.flatMap((node) => [node, ...nestedNodesOf(node)]);
}

function nestedNodesOf(node: GraphNode): GraphNode[] {
  const config = record(node.config);
  const graphs: Array<BranchWorkflowGraph | undefined> = [];
  if (config.primitive === "forEach") graphs.push(graphOf(config.graph));
  if (config.primitive === "conditionalFlow" && Array.isArray(config.branches)) {
    for (const branch of config.branches) graphs.push(graphOf(record(branch).graph));
  }
  return graphs.flatMap((graph) => (graph === undefined ? [] : nodesOf(graph)));
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

function graphOf(value: unknown): BranchWorkflowGraph | undefined {
  const graph = record(value);
  return Array.isArray(graph.nodes) ? graph as unknown as BranchWorkflowGraph : undefined;
}

function text(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : null;
}

function record(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null ? value as Record<string, unknown> : {};
}
