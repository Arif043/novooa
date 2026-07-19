import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "../task-runner/node-executor.js";
import {FirestoreTeamFileStore} from "../task-runner/stores/firestore-team-file-store.js";
import {type TeamFileStore} from "../task-runner/stores/team-file-store.js";
import {
  type NodeAttachment,
  type WorkflowNode,
} from "../task-runner/task-definition.js";

const defaultFileStore = new FirestoreTeamFileStore();

export const readFileNodeExecutor: NodeExecutor = {
  primitive: "readFile",
  async execute(input, runContext) {
    const output = await readNodeFile(
      defaultFileStore,
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
