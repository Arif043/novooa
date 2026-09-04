import {createPythonScriptExecutor} from "../../local/python-script-executor.js";
import {type NodeExecutor, executedNode, textForParentOutputs, textOutputs} from "../runner/node-executor.js";
import {logInfo, logReadableInfo} from "../runner/structured-logger.js";

export const scriptNodeExecutor: NodeExecutor = {
  primitive: "script",
  async execute(input, runContext) {
    const parentOutput = textForParentOutputs(input.parentOutputs);
    const output = await createPythonScriptExecutor(input.attachmentWorkspace).execute({
      input: runContext.resolveTemplates(parentOutput),
      script: runContext.resolveTemplates(scriptFor(input.node)),
      variables: runContext.variables,
    });
    logScriptPrints(output.printed);
    return executedNode(input.node, textOutputs(output.output), {variables: output.variables});
  },
};

function logScriptPrints(printed: string): void {
  if (printed.trim().length === 0) return;
  logReadableInfo(["[Script-Log]", printed.trimEnd()].join("\n"));
  logInfo("script_node.printed", {length: printed.length, preview: printed.slice(0, 1000)});
}

function scriptFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]): string {
  return node.config.primitive === "script" ? node.config.script : "";
}
