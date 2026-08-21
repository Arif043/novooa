import {type MediaReference} from "./workflow-value.js";

export type MediaInputDefinition = {
  instruction: string;
};

export type MediaInputFileReference = MediaReference;

export function validateMediaInputDefinition(
  definition: MediaInputDefinition,
): void {
  if (definition.instruction.trim().length === 0) {
    throw new Error("Die Medienaufnahme benötigt eine Anweisung.");
  }
}
