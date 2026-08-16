import {
  validateDialogInputValues,
} from "../entities/dialog-input.js";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type TaskResumeState,
} from "../entities/task.js";

export function responseOutputsForTaskRun(
  resumeState: TaskResumeState,
  output: string,
  formValues: Record<string, unknown>,
): Record<string, NodeOutputValue> {
  const waitingResult = waitingResultFor(resumeState);
  if (waitingResult?.dialogInput === undefined) return textOutput(output);
  return dialogInputOutputs(waitingResult, formValues);
}

function waitingResultFor(resumeState: TaskResumeState) {
  return resumeState.nodeResults.find(
    (result) => result.nodeId === resumeState.waitingNodeId,
  );
}

function textOutput(output: string): Record<string, NodeOutputValue> {
  return {text: {type: "string", value: output}};
}

function dialogInputOutputs(
  result: NodeExecutionResult,
  formValues: Record<string, unknown>,
): Record<string, NodeOutputValue> {
  const values = validateDialogInputValues(result.dialogInput!, formValues);
  const outputs = Object.entries(values).reduce<Record<string, NodeOutputValue>>(
    (current, [name, value]) => {
      current[name] = outputFor(value);
      return current;
    },
    {},
  );
  return {...textOutput(JSON.stringify(values)), ...outputs};
}

function outputFor(value: string | number | boolean): NodeOutputValue {
  if (typeof value === "number") return {type: "number", value};
  if (typeof value === "boolean") return {type: "boolean", value};
  return {type: "string", value};
}
