import {ok} from "neverthrow";
import {ScriptExecutionError, type ScriptExecutionResult} from "../entities/script-execution.js";
import {type ConsoleOutput} from "../entities/task.js";
import {type NodeOutputValue} from "../entities/workflow-value.js";
import {ScriptWorkflowOutputError, workflowOutputsFrom} from "../services/script-workflow-outputs.js";
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
      return ok(executedNode(node, nodeOutputsOf(output, consoleOutput), {
        variables: output.variables, console: hasOutput(consoleOutput) ? consoleOutput : undefined,
      }));
    },
  };
}

/**
 * Definiert das Script Workflow-Ausgaben, sind sie seine fachlichen Werte — flach unter ihrem Namen, ohne
 * `value`; `output` gilt dann nicht. Sonst bleibt es beim Text-Output wie bisher.
 */
function nodeOutputsOf(output: ScriptExecutionResult, consoleOutput: ConsoleOutput): Record<string, NodeOutputValue> {
  const workflowOutputs = output.workflowOutputs ?? [];
  if (workflowOutputs.length === 0) return textOutputs(output.output);
  try {
    return workflowOutputsFrom(workflowOutputs);
  } catch (error) {
    if (!(error instanceof ScriptWorkflowOutputError)) throw error;
    // Wie ein Fehler im Script selbst: mit dessen Ausgabe, damit sie in den Aktivitäten steht.
    throw new ScriptExecutionError(error.message, consoleOutput.stdout, consoleOutput.stderr);
  }
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
