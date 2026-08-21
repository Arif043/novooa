import {
  type NodeExecutor,
  executedNode,
  singleParentOutput,
} from "../runner/node-executor.js";
import {
  type FileContent,
  type TeamFileStore,
  type WrittenFile,
} from "../../../../files/domain/repositories/team-file-store.js";
import {
  contentTypeFor,
  fileNameFor,
  targetFileIdFor,
} from "./write-file-node-config.js";
import {fileContentFor} from "../runner/media-value-loader.js";
import {
  fileMetadataOutputs,
  fileOutputFor,
} from "../runner/file-output-values.js";
import {imageExtensionFor} from "./image-data-url.js";

export const writeFileNodeExecutor: NodeExecutor = {
  primitive: "writeFile",
  async execute(input, runContext) {
    const parentOutput = singleParentOutput(input.parentOutputs);
    const source = await sourceContentFor(parentOutput, runContext);
    const writeInput = {
      teamId: runContext.teamId,
      content: source.content,
      fileName: runContext.resolveTemplates(fileNameFor(input.node)),
      contentType: runContext.resolveTemplates(contentTypeFor(input.node)),
      targetFileId: targetFileIdFor(input.node),
    };
    const file = await writeNodeFile(
      runContext.teamFileStore,
      mediaWriteInputFor(writeInput, source.sourceContentType),
    );
    return executedNode(input.node, fileOutputs(file));
  },
};

async function sourceContentFor(
  output: ReturnType<typeof singleParentOutput>,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<SourceContent> {
  if (output === undefined) return {content: ""};
  if (output.type === "media" || output.type === "file") {
    const file = await fileContentFor(
      output.value,
      runContext.teamId,
      runContext.fileContentReader,
    );
    return {content: file.content, sourceContentType: file.contentType};
  }
  return {content: runContext.resolveTemplates(contentFrom(output))};
}

function contentFrom(
  output: Exclude<ReturnType<typeof singleParentOutput>, undefined>,
): string {
  if (output.type === "string" || output.type === "datetime") return output.value;
  if (output.type === "number" || output.type === "boolean") return String(output.value);
  return JSON.stringify(output.value);
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
