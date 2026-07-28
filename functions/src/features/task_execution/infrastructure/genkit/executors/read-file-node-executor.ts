import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "../runner/node-executor.js";
import {type TeamFileStore} from "../../../../files/domain/repositories/team-file-store.js";
import {
  type NodeAttachment,
  type WorkflowNode,
} from "../runner/task-definition.js";

export const readFileNodeExecutor: NodeExecutor = {
  primitive: "readFile",
  async execute(input, runContext) {
    const output = await readNodeFile(
      runContext.teamFileStore,
      runContext.teamId,
      input.node,
    );
    return executedNode(input.node, textOutputs(output));
  },
};

async function readNodeFile(
  fileStore: TeamFileStore,
  teamId: string,
  node: WorkflowNode,
): Promise<string> {
  return fileStore.readTextFile(teamId, selectedFileFor(node));
}

function selectedFileFor(node: WorkflowNode): NodeAttachment {
  if (node.config.primitive !== "readFile" || node.config.file === undefined) {
    throw new Error("Datei lesen: Es wurde keine Datei ausgewählt.");
  }
  return node.config.file;
}
