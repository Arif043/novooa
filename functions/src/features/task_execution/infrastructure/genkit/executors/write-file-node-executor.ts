import {
  type NodeExecutor,
  executedNode,
  parentOutputFor,
  textOutputs,
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

export const writeFileNodeExecutor: NodeExecutor = {
  primitive: "writeFile",
  async execute(input, runContext) {
    const parentContent = parentOutputFor(
      input.node,
      runContext.task,
      runContext.results,
    );
    const file = await writeNodeFile(runContext.teamFileStore, writeInputFor({
      teamId: runContext.teamId,
      content: runContext.resolveTemplates(parentContent),
      fileName: runContext.resolveTemplates(fileNameFor(input.node)),
      contentType: runContext.resolveTemplates(contentTypeFor(input.node)),
      targetFileId: targetFileIdFor(input.node),
    }));
    return executedNode(input.node, fileOutputs(file));
  },
};

type WriteNodeFileInput = {
  teamId: string;
  content: FileContent;
  fileName: string;
  contentType: string;
  targetFileId: string | null;
};

async function writeNodeFile(
  fileStore: TeamFileStore,
  input: WriteNodeFileInput,
) {
  ensureConfigured(input.fileName);
  return fileStore.writeTeamFile(input);
}

function writeInputFor(input: WriteNodeFileInput): WriteNodeFileInput {
  const image = imageContentFrom(input.content);
  if (image === null) return input;
  return {
    ...input,
    content: image.bytes,
    contentType: image.contentType,
    fileName: imageFileNameFor(input.fileName, image.contentType),
  };
}

type ImageContent = {
  bytes: Uint8Array;
  contentType: string;
};

function imageContentFrom(content: FileContent): ImageContent | null {
  if (typeof content !== "string" || !content.startsWith("data:image/")) {
    return null;
  }
  const match = imageDataUrlPattern.exec(content.trim());
  if (!match) throw new Error("Datei schreiben: Bild-Data-URL ist ungültig.");
  const bytes = Buffer.from(match[2], "base64");
  if (bytes.byteLength === 0) {
    throw new Error("Datei schreiben: Bild-Data-URL enthält keine Bilddaten.");
  }
  return {bytes, contentType: match[1].toLowerCase()};
}

function imageFileNameFor(fileName: string, contentType: string): string {
  const extension = imageExtensionFor(contentType);
  const baseName = fileName.replace(/\.[^.]+$/, "");
  return `${baseName || "bild"}.${extension}`;
}

function imageExtensionFor(contentType: string): string {
  const extensions: Record<string, string> = {
    "image/png": "png",
    "image/jpeg": "jpg",
    "image/webp": "webp",
    "image/gif": "gif",
    "image/avif": "avif",
  };
  return extensions[contentType] ?? "img";
}

const imageDataUrlPattern = /^data:(image\/[a-z0-9.+-]+);base64,([A-Za-z0-9+/]+={0,2})$/i;

function ensureConfigured(fileName: string): void {
  if (fileName.trim().length > 0) return;
  throw new Error("Datei schreiben: Es wurde keine Ausgabedatei ausgewählt.");
}

function fileOutputs(file: WrittenFile) {
  return {
    ...textOutputs(JSON.stringify(file)),
    fileId: {type: "string" as const, value: file.fileId},
    versionId: {type: "string" as const, value: file.versionId},
    storagePath: {type: "string" as const, value: file.storagePath},
    displayName: {type: "string" as const, value: file.displayName},
    contentType: {type: "string" as const, value: file.contentType},
    sizeBytes: {type: "number" as const, value: file.sizeBytes},
    folderId: {type: "json" as const, value: file.folderId},
    isNewFile: {type: "boolean" as const, value: file.isNewFile},
  };
}
