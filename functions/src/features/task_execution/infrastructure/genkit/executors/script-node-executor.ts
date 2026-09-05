import {createPythonScriptExecutor} from "../../local/python-script-executor.js";
import {type NodeExecutor, executedNode, textForParentOutputs, textOutputs} from "../../../domain/executors/node-executor.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {logInfo, logReadableInfo} from "../runner/structured-logger.js";

export function createScriptNodeExecutor(
  workspace?: NodeAttachmentWorkspace,
): NodeExecutor {
  return {
    primitive: "script",
    async execute(input, runContext) {
      const parentOutput = textForParentOutputs(input.parentOutputs);
      const output = await createPythonScriptExecutor(workspace).execute({
      input: runContext.resolveTemplates(parentOutput),
      script: runContext.resolveTemplates(scriptFor(input.node)),
      variables: runContext.variables,
      });
      logScriptPrints(output.printed);
      return executedNode(input.node, textOutputs(output.output), {variables: output.variables});
    },
  };
}

function logScriptPrints(printed: string): void {
  if (printed.trim().length === 0) return;
  logReadableInfo(["[Script-Log]", printed.trimEnd()].join("\n"));
  logInfo("script_node.printed", {length: printed.length, preview: printed.slice(0, 1000)});
}

function scriptFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]): string {
  return node.config.primitive === "script" ? node.config.script : "";
}
