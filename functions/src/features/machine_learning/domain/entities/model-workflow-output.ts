import {type TransformationParameter} from "./model-contract.js";

export const modelWorkflowValueTypes = [
  "string",
  "number",
  "boolean",
  "json",
  "audio",
] as const;

export type ModelWorkflowValueType =
  (typeof modelWorkflowValueTypes)[number];

export type ModelWorkflowOutput = {
  name: string;
  type: ModelWorkflowValueType;
  mapping: TransformationParameter;
};

export function validateWorkflowOutput(output: ModelWorkflowOutput): void {
  requiredName(output.name);
  requiredType(output.type);
  validMapping(output.mapping);
}

function requiredName(value: string): void {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error("Die Workflow-Ausgabe benötigt einen Namen.");
  }
}

function requiredType(value: ModelWorkflowValueType): void {
  if (
    typeof value !== "string" ||
    !modelWorkflowValueTypes.includes(value)
  ) {
    throw new Error("Die Workflow-Ausgabe benötigt einen unterstützten Workflow-Typ.");
  }
}

function validMapping(value: TransformationParameter): void {
  if (value === undefined) {
    throw new Error("Die Workflow-Ausgabe benötigt ein Mapping.");
  }
}
