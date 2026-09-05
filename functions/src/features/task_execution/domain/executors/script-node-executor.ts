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
    async execute(input, runContext) {
      const parentOutput = textForParentOutputs(input.parentOutputs);
      const output = await scriptExecutor.execute({
        input: runContext.resolveTemplates(parentOutput),
        script: runContext.resolveTemplates(scriptFor(input.node)),
        variables: runContext.variables,
      });
      observeOutput(output.printed);
      return executedNode(input.node, textOutputs(output.output), {variables: output.variables});
    },
  };
}

function scriptFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]): string {
  return node.config.primitive === "script" ? node.config.script : "";
}
