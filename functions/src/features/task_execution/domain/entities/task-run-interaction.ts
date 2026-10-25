import {type DialogInputDefinition} from "./dialog-input.js";

export type TaskRunInteraction =
  | {kind: "approval"; instruction: string}
  | ({kind: "dialogInput"} & DialogInputDefinition);

export function approvalInteraction(instruction: string): TaskRunInteraction {
  return {kind: "approval", instruction};
}

export function dialogInputInteraction(
  definition: DialogInputDefinition,
): TaskRunInteraction {
  return {kind: "dialogInput", ...definition};
}
