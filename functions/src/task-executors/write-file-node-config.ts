import {type WorkflowNode} from "../task-runner/task-definition.js";

export function fileNameFor(node: WorkflowNode): string {
  const value = node.config.primitive === "writeFile" ? node.config.fileName : "";
  return sanitizedName(value || "ausgabe.txt");
}

export function contentTypeFor(node: WorkflowNode): string {
  if (node.config.primitive !== "writeFile") return "text/plain";
  return node.config.contentType.trim() || "text/plain";
}

export function targetFileIdFor(node: WorkflowNode): string | null {
  if (node.config.primitive !== "writeFile") return null;
  const fileId = node.config.fileId?.trim();
  return fileId && fileId.length > 0 ? fileId : null;
}

export function storagePathFor(
  teamId: string,
  fileId: string,
  versionId: string,
  fileName: string,
): string {
  return `teams/${teamId}/files/${fileId}/versions/${versionId}/${fileName}`;
}

function sanitizedName(value: string): string {
  return value.trim().replace(/[\\/]/g, "_");
}
