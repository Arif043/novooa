import {err, ok} from "neverthrow";
import {nodeFailures} from "../entities/node-failures.js";
import {
  type NodeExecutor,
  executedNode,
} from "./node-executor.js";
import {
  type FileContent,
  type WrittenFile,
} from "../../../files/domain/repositories/team-file-store.js";
import {
  contentTypeFor,
  fileNameFor,
  targetFileIdFor,
  targetFolderIdFor,
} from "../services/write-file-node-config.js";
import {
  fileMetadataOutputs,
  fileOutputFor,
} from "../services/file-output-values.js";
import {fileNameForContentType, workflowValueContent} from "../services/workflow-value-content.js";

export const writeFileNodeExecutor: NodeExecutor = {
  primitive: "writeFile",
  async execute(node, runContext) {
    const source = await workflowValueContent(
      runContext.templateExpressionResolver.resolveValue(contentTemplateFor(node)),
      {teamId: runContext.teamId, reader: runContext.fileContentReader},
    );
    const writeInput = {
      teamId: runContext.teamId,
      content: source.content,
      fileName: runContext.templateExpressionResolver.resolveText(fileNameFor(node)),
      contentType: runContext.templateExpressionResolver.resolveText(contentTypeFor(node)),
      targetFileId: targetFileIdFor(node),
      folderId: targetFolderIdFor(node),
    };
    if (writeInput.fileName.trim().length === 0) return err(nodeFailures.settingMissing("outputFile"));
    const file = await runContext.teamFileStore.writeTeamFile(writeInputFor(writeInput, source.sourceContentType));
    return ok(executedNode(node, fileOutputs(file)));
  },
};

function contentTemplateFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  return node.config.primitive === "writeFile" ? node.config.contentTemplate ?? "" : "";
}

/** Bringt der Wert seinen eigenen Content-Type mit (Bild, Tabelle als XLSX), überschreibt er Typ und Endung;
 * reiner Text behält die konfigurierte Ausgabe. */
function writeInputFor(input: WriteNodeFileInput, sourceContentType?: string): WriteNodeFileInput {
  if (sourceContentType === undefined) return input;
  return {...input, contentType: sourceContentType, fileName: fileNameForContentType(input.fileName, sourceContentType)};
}

type WriteNodeFileInput = {
  teamId: string;
  content: FileContent;
  fileName: string;
  contentType: string;
  targetFileId: string | null;
  folderId: string | null;
};

function fileOutputs(file: WrittenFile) {
  return {
    value: fileOutputFor(file),
    ...fileMetadataOutputs(file),
  };
}
