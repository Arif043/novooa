export const modelTensorDataTypes = [
  "float32",
  "float64",
  "int64",
  "int32",
  "int16",
  "int8",
  "uint8",
  "bool",
] as const;

export type ModelTensorDataType = (typeof modelTensorDataTypes)[number];
export type TensorDimension = number | "dynamic";
export const modelInputSourceTypes = [
  "image",
  "audio",
  "file",
  "text",
  "datetime",
  "number",
  "boolean",
  "json",
  "tensor",
] as const;
export type ModelInputSourceType = (typeof modelInputSourceTypes)[number];
export type TransformationParameter =
  | string
  | number
  | boolean
  | readonly TransformationParameter[]
  | TransformationParameterRecord;

export interface TransformationParameterRecord {
  readonly [key: string]: TransformationParameter;
}

export type Transformation = {
  type: string;
  parameters: Readonly<Record<string, TransformationParameter>>;
  result?: string;
};

export type TransformationPipeline = readonly Transformation[];

export type Tensor = {
  name: string;
  dataType: ModelTensorDataType;
  shape: readonly TensorDimension[];
};

export type ModelInput = Tensor & {
  source: ModelInputSourceType;
  transformations: TransformationPipeline;
};

export type ModelOutput = Tensor & {
  semantic: string;
  transformations: TransformationPipeline;
  workflowOutput: ModelWorkflowOutput;
};

export type ModelContract = {
  inputs: readonly ModelInput[];
  outputs: readonly ModelOutput[];
};

export function validateModelContract(contract: ModelContract): void {
  requiredDefinitions(
    contract.inputs,
    "Das Modell benötigt mindestens einen Eingang.",
  );
  requiredDefinitions(
    contract.outputs,
    "Das Modell benötigt mindestens einen Ausgang.",
  );
  validateInput(contract.inputs);
  validateOutput(contract.outputs);
}

function validateInput(inputs: readonly ModelInput[]): void {
  uniqueTensorNames(inputs);
  for (const input of inputs) {
    validateTensor(input);
    validateTransformations(input.transformations);
  }
}

function validateOutput(outputs: readonly ModelOutput[]): void {
  uniqueTensorNames(outputs);
  uniqueSemantics(outputs);
  uniqueWorkflowOutputNames(outputs);
  for (const output of outputs) {
    validateTensor(output);
    if (output.semantic.trim().length === 0)
      throw new Error("Jeder Modellausgang benötigt eine Semantik.");
    validateOutputTransformations(output);
  }
}

function uniqueSemantics(outputs: readonly ModelOutput[]): void {
  const semantics = outputs.map((output) => output.semantic.trim());
  if (new Set(semantics).size !== semantics.length) {
    throw new Error("Modellausgänge müssen eindeutige Semantiken haben.");
  }
}

function uniqueWorkflowOutputNames(outputs: readonly ModelOutput[]): void {
  const names = outputs.map((output) => output.workflowOutput.name.trim());
  if (new Set(names).size !== names.length) {
    throw new Error("Workflow-Ausgaben müssen eindeutige Namen haben.");
  }
}

function requiredDefinitions(
  definitions: readonly unknown[],
  message: string,
): void {
  if (definitions.length === 0) throw new Error(message);
}

function uniqueTensorNames(tensors: readonly Tensor[]): void {
  const names = tensors.map((tensor) => tensor.name.trim());
  if (names.some((name) => name.length === 0))
    throw new Error("Tensor-Namen dürfen nicht leer sein.");
  if (new Set(names).size !== names.length)
    throw new Error("Tensor-Namen müssen eindeutig sein.");
}

function validateTensor(tensor: Tensor): void {
  if (!modelTensorDataTypes.includes(tensor.dataType)) {
    throw new Error(
      `Nicht unterstützter Tensor-Datentyp: ${tensor.dataType}`,
    );
  }
  if (
    tensor.shape.length === 0 ||
    !tensor.shape.every(validDimension)
  ) {
    throw new Error(`Die Tensor-Form von ${tensor.name} ist ungültig.`);
  }
}

function validDimension(dimension: TensorDimension): boolean {
  return (
    dimension === "dynamic" ||
    (Number.isSafeInteger(dimension) && dimension > 0)
  );
}

function validateTransformations(
  transformations: readonly Transformation[],
): void {
  for (const transformation of transformations) {
    if (transformation.type.trim().length === 0) {
      throw new Error("Jede Transformation benötigt einen Typ.");
    }
    if (transformation.result !== undefined && transformation.result.trim().length === 0) {
      throw new Error("Der Name des Transformations-Ergebnisses darf nicht leer sein.");
    }
    for (const value of Object.values(transformation.parameters)) {
      if (!validParameter(value))
        throw new Error("Ein Transformationsparameter ist ungültig.");
    }
  }
}

function validateOutputTransformations(output: ModelOutput): void {
  validateTransformations(output.transformations);
  uniqueTransformationResults(output.transformations);
  validateWorkflowOutput(output.workflowOutput);
}

function uniqueTransformationResults(transformations: TransformationPipeline): void {
  const names = transformations
    .map((transformation) => transformation.result?.trim())
    .filter((name): name is string => name !== undefined && name.length > 0);
  if (names.length !== new Set(names).size) {
    throw new Error("Transformations-Ergebnisse müssen eindeutig sein.");
  }
}

function validParameter(value: TransformationParameter): boolean {
  if (typeof value === "number") return Number.isFinite(value);
  if (typeof value === "string" || typeof value === "boolean") return true;
  if (Array.isArray(value)) return value.every(validParameter);
  return Object.values(value).every(validParameter);
}
import {
  type ModelWorkflowOutput,
  validateWorkflowOutput,
} from "./model-workflow-output.js";
