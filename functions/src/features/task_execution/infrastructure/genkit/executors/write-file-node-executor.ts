import {
  type NodeExecutor,
  executedNode,
  parentOutputFor,
  textOutputs,
} from "../runner/node-executor.js";
import {type TeamFileStore} from "../../../../files/domain/repositories/team-file-store.js";
import {type WrittenFile} from "../../../../files/domain/repositories/team-file-store.js";
import {
  contentTypeFor,
  fileNameFor,
  targetFileIdFor,
} from "./write-file-node-config.js";

export const writeFileNodeExecutor: NodeExecutor = {
  primitive: "writeFile",
  async execute(input, runContext) {
    const content = parentOutputFor(
      input.node,
      runContext.task,
      runContext.results,
    );
    const file = await writeNodeFile(runContext.teamFileStore, {
      teamId: runContext.teamId,
      content: runContext.resolveTemplates(content),
      fileName: runContext.resolveTemplates(fileNameFor(input.node)),
      contentType: runContext.resolveTemplates(contentTypeFor(input.node)),
      targetFileId: targetFileIdFor(input.node),
    });
    return executedNode(input.node, fileOutputs(file));
  },
};

type WriteNodeFileInput = {
  teamId: string;
  content: string;
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
