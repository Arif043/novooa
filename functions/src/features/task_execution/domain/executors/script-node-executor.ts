import {ScriptExecutionError} from "../entities/script-execution.js";
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
      const output = await executeObserved(scriptExecutor, observeOutput, {
        input: runContext.templateExpressionResolver.resolveText(inputTemplateFor(node)),
        script: runContext.templateExpressionResolver.resolveText(scriptFor(node)),
        variables: runContext.variables,
      });
      observeOutput(output.printed);
      return executedNode(node, textOutputs(output.output), {variables: output.variables});
    },
  };
}

/** Auch ein gescheitertes Script hat Ausgabe geliefert; sie gehört ins Protokoll, bevor der Fehler weitergereicht wird. */
async function executeObserved(
  scriptExecutor: ScriptExecutor,
  observeOutput: ScriptOutputObserver,
  request: Parameters<ScriptExecutor["execute"]>[0],
) {
  try {
    return await scriptExecutor.execute(request);
  } catch (error) {
    if (error instanceof ScriptExecutionError) observeOutput(error.printed);
    throw error;
  }
}

function scriptFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  return node.config.primitive === "script" ? node.config.script : "";
}

function inputTemplateFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  return node.config.primitive === "script" ? node.config.inputTemplate ?? "" : "";
}
