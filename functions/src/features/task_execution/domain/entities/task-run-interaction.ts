import {type DialogInputDefinition} from "./dialog-input.js";
import {type MediaInputDefinition} from "./media-input.js";

export type TaskRunInteraction =
  | {kind: "approval"; instruction: string}
  | ({kind: "dialogInput"} & DialogInputDefinition)
  | ({kind: "mediaInput"} & MediaInputDefinition);

export function approvalInteraction(instruction: string): TaskRunInteraction {
  return {kind: "approval", instruction};
}

export function dialogInputInteraction(
  definition: DialogInputDefinition,
): TaskRunInteraction {
  return {kind: "dialogInput", ...definition};
}

export function mediaInputInteraction(
  definition: MediaInputDefinition,
): TaskRunInteraction {
  return {kind: "mediaInput", ...definition};
}
