import {
  type NodeExecutor,
  executedNode,
  parentOutputFor,
  textOutputs,
} from "../task-runner/node-executor.js";
import {FirestoreTeamFileStore} from "../task-runner/stores/firestore-team-file-store.js";
import {type TeamFileStore} from "../task-runner/stores/team-file-store.js";
import {
  contentTypeFor,
  fileNameFor,
  targetFileIdFor,
} from "./write-file-node-config.js";

const defaultFileStore = new FirestoreTeamFileStore();

export const writeFileNodeExecutor: NodeExecutor = {
  primitive: "writeFile",
  async execute(input, runContext) {
    const content = parentOutputFor(
      input.node,
      runContext.task,
      runContext.results,
    );
    const file = await writeNodeFile(defaultFileStore, {
      teamId: runContext.teamId,
      content: runContext.resolveTemplates(content),
      fileName: runContext.resolveTemplates(fileNameFor(input.node)),
      contentType: runContext.resolveTemplates(contentTypeFor(input.node)),
      targetFileId: targetFileIdFor(input.node),
    });
    return executedNode(input.node, textOutputs(JSON.stringify(file)));
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
