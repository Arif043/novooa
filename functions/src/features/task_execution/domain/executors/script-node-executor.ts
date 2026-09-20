import {type ScriptExecutor} from "./script-executor.js";
import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "./node-executor.js";

export type ScriptOutputObserver = (printed: string) => void;

export function createScriptNodeExecutor(
  scriptExecutor: ScriptExecutor,
  observeOutput: ScriptOutputObserver = () => undefined,
): NodeExecutor {
  return {
    primitive: "script",
    async execute(node, runContext) {
      const output = await scriptExecutor.execute({
        input: runContext.templateExpressionResolver.resolveText(inputTemplateFor(node)),
        script: runContext.templateExpressionResolver.resolveText(scriptFor(node)),
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

function inputTemplateFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  return node.config.primitive === "script" ? node.config.inputTemplate ?? "" : "";
}
