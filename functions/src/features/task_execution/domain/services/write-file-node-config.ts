import {type WorkflowNode} from "../entities/task.js";

export function fileNameFor(node: WorkflowNode): string {
  const value = node.config.primitive === "writeFile" ? node.config.fileName : "";
  return sanitizedName(value);
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

export function targetFolderIdFor(node: WorkflowNode): string | null {
  if (node.config.primitive !== "writeFile") return null;
  const folderId = node.config.folderId?.trim();
  return folderId && folderId.length > 0 ? folderId : null;
}

function sanitizedName(value: string): string {
  return value.trim().replace(/[\\/]/g, "_");
}
