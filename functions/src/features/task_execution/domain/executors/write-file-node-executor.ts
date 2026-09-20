import {
  type NodeExecutor,
  executedNode,
} from "./node-executor.js";
import {
  type FileContent,
  type TeamFileStore,
  type WrittenFile,
} from "../../../files/domain/repositories/team-file-store.js";
import {
  contentTypeFor,
  fileNameFor,
  targetFileIdFor,
} from "../services/write-file-node-config.js";
import {
  fileMetadataOutputs,
  fileOutputFor,
} from "../services/file-output-values.js";
import {imageExtensionFor} from "../services/image-content-type.js";

export const writeFileNodeExecutor: NodeExecutor = {
  primitive: "writeFile",
  async execute(node, runContext) {
    const source = await sourceContentFor(
      runContext.templateExpressionResolver.resolveValue(contentTemplateFor(node)),
      runContext,
    );
    const writeInput = {
      teamId: runContext.teamId,
      content: source.content,
      fileName: runContext.templateExpressionResolver.resolveText(fileNameFor(node)),
      contentType: runContext.templateExpressionResolver.resolveText(contentTypeFor(node)),
      targetFileId: targetFileIdFor(node),
    };
    const file = await writeNodeFile(
      runContext.teamFileStore,
      mediaWriteInputFor(writeInput, source.sourceContentType),
    );
    return executedNode(node, fileOutputs(file));
  },
};

async function sourceContentFor(
  value: unknown,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<SourceContent> {
  if (isFileReference(value)) {
    const file = await runContext.fileContentReader.readTeamFileContent(
      runContext.teamId,
      value.fileId,
      value.versionId,
    );
    return {content: file.content, sourceContentType: file.contentType};
  }
  return {content: contentFrom(value)};
}

function contentTemplateFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  return node.config.primitive === "writeFile" ? node.config.contentTemplate ?? "" : "";
}

function contentFrom(value: unknown): string {
  if (value === undefined || value === null) return "";
  if (typeof value === "string") return value;
  return typeof value === "number" || typeof value === "boolean"
    ? String(value)
    : JSON.stringify(value);
}

function isFileReference(value: unknown): value is {fileId: string; versionId: string} {
  if (typeof value !== "object" || value === null) return false;
  const reference = value as Record<string, unknown>;
  return typeof reference.fileId === "string" && typeof reference.versionId === "string";
}

function mediaWriteInputFor(
  input: WriteNodeFileInput,
  sourceContentType?: string,
): WriteNodeFileInput {
  if (sourceContentType === undefined) return input;
  const contentType = sourceContentType;
  return {
    ...input,
    contentType,
    fileName: contentType.startsWith("image/")
      ? imageFileNameFor(input.fileName, contentType)
      : input.fileName,
  };
}

type WriteNodeFileInput = {
  teamId: string;
  content: FileContent;
  fileName: string;
  contentType: string;
  targetFileId: string | null;
};

type SourceContent = {
  content: FileContent;
  sourceContentType?: string;
};

async function writeNodeFile(
  fileStore: TeamFileStore,
  input: WriteNodeFileInput,
) {
  ensureConfigured(input.fileName);
  return fileStore.writeTeamFile(input);
}

function imageFileNameFor(fileName: string, contentType: string): string {
  const extension = imageExtensionFor(contentType);
  const baseName = fileName.replace(/\.[^.]+$/, "");
  return `${baseName || "bild"}.${extension}`;
}

function ensureConfigured(fileName: string): void {
  if (fileName.trim().length > 0) return;
  throw new Error("Datei schreiben: Es wurde keine Ausgabedatei ausgewählt.");
}

function fileOutputs(file: WrittenFile) {
  return {
    value: fileOutputFor(file),
    ...fileMetadataOutputs(file),
  };
}
