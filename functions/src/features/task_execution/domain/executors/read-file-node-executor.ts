import {nodeFailures} from "../entities/node-failures.js";
import {err, ok} from "neverthrow";
import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "./node-executor.js";
import {type NodeAttachment, type WorkflowNode} from "../entities/task.js";

export const readFileNodeExecutor: NodeExecutor = {
  primitive: "readFile",
  async execute(node, runContext) {
    const file = selectedFileFor(node);
    if (file === undefined) return err(nodeFailures.settingMissing("inputFile"));
    const output = await runContext.teamFileStore.readTextFile(runContext.teamId, file);
    return ok(executedNode(node, textOutputs(output)));
  },
};

function selectedFileFor(node: WorkflowNode): NodeAttachment | undefined {
  return node.config.primitive === "readFile" ? node.config.file : undefined;
}
