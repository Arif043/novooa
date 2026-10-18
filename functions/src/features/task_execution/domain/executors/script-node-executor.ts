import {err, type Result} from "neverthrow";
import {type NodeFailure} from "../entities/node-failure.js";
import {type ScriptExecutionResult} from "../entities/script-execution.js";
import {type ConsoleOutput} from "../entities/task.js";
import {type NodeOutputValue} from "../entities/workflow-value.js";
import {workflowOutputsFrom} from "../services/script-workflow-outputs.js";
import {type ScriptExecutor} from "./script-executor.js";
import {type NodeExecutor, executedNode} from "./node-executor.js";

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
      const outputOrFailure = await scriptExecutor.execute({
        script: runContext.templateExpressionResolver.resolveText(scriptFor(node)),
        variables: runContext.variables,
      });
      // Auch ein gescheitertes Script hat Ausgabe geliefert; sie gehört ins Protokoll.
      if (outputOrFailure.isErr()) {
        observeFailure(outputOrFailure.error, observeOutput);
        return err(outputOrFailure.error);
      }
      const output = outputOrFailure.value;
      const consoleOutput = {stdout: output.printed, stderr: output.errorOutput ?? ""};
      observeOutput({printed: consoleOutput.stdout, errorOutput: consoleOutput.stderr});
      return nodeOutputsOf(output, consoleOutput).map((outputs) => executedNode(node, outputs, {
        variables: output.variables, console: hasOutput(consoleOutput) ? consoleOutput : undefined,
      }));
    },
  };
}

/**
 * Die Werte eines Scripts sind allein seine `workflow_output`-Aufrufe — flach unter ihrem Namen; ohne
 * Aufrufe hat der Baustein keine Werte. Eine ungültige Ausgabe trägt die Konsole des Scripts, damit sie
 * in den Aktivitäten steht.
 */
function nodeOutputsOf(
  output: ScriptExecutionResult, consoleOutput: ConsoleOutput,
): Result<Record<string, NodeOutputValue>, NodeFailure> {
  return workflowOutputsFrom(output.workflowOutputs ?? []).mapErr((failure) => failure.withConsole(consoleOutput));
}

function hasOutput(output: ConsoleOutput): boolean {
  return output.stdout.length > 0 || output.stderr.length > 0;
}

function observeFailure(failure: NodeFailure, observeOutput: ScriptOutputObserver): void {
  if (failure.console) observeOutput({printed: failure.console.stdout, errorOutput: failure.console.stderr});
}

function scriptFor(node: Parameters<NodeExecutor["execute"]>[0]): string {
  return node.config.primitive === "script" ? node.config.script : "";
}
