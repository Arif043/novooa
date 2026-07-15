import {getApps, initializeApp} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "../task-runner/node-executor.js";
import {
  type NodeAttachment,
  type WorkflowNode,
} from "../task-runner/task-definition.js";

export const readFileNodeExecutor: NodeExecutor = {
  primitive: "readFile",
  async execute(input, runContext) {
    const file = selectedFileFor(input.node);
    ensureTeamFile(file, runContext.teamId);
    const output = await readStorageFile(file);
    return executedNode(input.node, textOutputs(output));
  },
};

async function readStorageFile(file: NodeAttachment): Promise<string> {
  initializeAdminApp();
  const storageFile = getStorage().bucket().file(file.storagePath);
  const [content] = await storageFile.download();
  return content.toString("utf8");
}

function selectedFileFor(node: WorkflowNode): NodeAttachment {
  if (node.config.primitive !== "readFile" || node.config.file === undefined) {
    throw new Error("Datei lesen: Es wurde keine Datei ausgewählt.");
  }
  return node.config.file;
}

function ensureTeamFile(file: NodeAttachment, teamId: string): void {
  if (file.storagePath.startsWith(teamFilePrefix(teamId))) return;
  throw new Error("Datei lesen: Die Datei gehört nicht zum aktuellen Team.");
}

function teamFilePrefix(teamId: string): string {
  return `teams/${teamId}/files/`;
}

function initializeAdminApp(): void {
  if (getApps().length === 0) initializeApp();
}
