import {ScriptExecutionError} from "../entities/script-execution.js";
import {type ConsoleOutput} from "../entities/task.js";
import {type ScriptExecutor} from "./script-executor.js";
import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "./node-executor.js";

/** Die Ausgabe eines Script-Laufs, getrennt nach stdout und stderr. */
export type ScriptOutput = {printed: string; errorOutput: string};

export type ScriptOutputObserver = (output: ScriptOutput) => void;

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
      const consoleOutput = {stdout: output.printed, stderr: output.errorOutput ?? ""};
      observeOutput({printed: consoleOutput.stdout, errorOutput: consoleOutput.stderr});
      return executedNode(node, textOutputs(output.output), {
        variables: output.variables, console: hasOutput(consoleOutput) ? consoleOutput : undefined,
      });
    },
  };
}

function hasOutput(output: ConsoleOutput): boolean {
  return output.stdout.length > 0 || output.stderr.length > 0;
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
    if (error instanceof ScriptExecutionError) {
      observeOutput({printed: error.printed, errorOutput: error.errorOutput});
    }
    throw error;
  }
}

function scriptFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  return node.config.primitive === "script" ? node.config.script : "";
}

function inputTemplateFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  return node.config.primitive === "script" ? node.config.inputTemplate ?? "" : "";
}
