import {type ScriptExecutor} from "./script-executor.js";
import {
  type NodeExecutor,
  executedNode,
  textForParentOutputs,
  textOutputs,
} from "./node-executor.js";

export type ScriptOutputObserver = (printed: string) => void;

export function createScriptNodeExecutor(
  scriptExecutor: ScriptExecutor,
  observeOutput: ScriptOutputObserver = () => undefined,
): NodeExecutor {
  return {
    primitive: "script",
    async execute(node, runContext, parentOutputs) {
      const parentOutput = textForParentOutputs(parentOutputs);
      const output = await scriptExecutor.execute({
        input: runContext.resolveTemplates(parentOutput),
        script: runContext.resolveTemplates(scriptFor(node)),
        variables: runContext.variables,
      });
      observeOutput(output.printed);
      return executedNode(node, textOutputs(output.output), {variables: output.variables});
    },
  };
}

function scriptFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  return node.config.primitive === "script" ? node.config.script : "";
}
