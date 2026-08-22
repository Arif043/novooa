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
  | readonly TransformationParameter[];

export type Transformation = {
  type: string;
  parameters: Readonly<Record<string, TransformationParameter>>;
};

export type Tensor = {
  name: string;
  dataType: ModelTensorDataType;
  shape: readonly TensorDimension[];
};

export type ModelInput = Tensor & {
  source: ModelInputSourceType;
  preprocessing: readonly Transformation[];
};

export type ModelOutput = Tensor & {
  semantic: string;
  postprocessing: readonly Transformation[];
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
    validateTransformations(input.preprocessing);
  }
}

function validateOutput(outputs: readonly ModelOutput[]): void {
  uniqueTensorNames(outputs);
  for (const output of outputs) {
    validateTensor(output);
    if (output.semantic.trim().length === 0)
      throw new Error("Jeder Modellausgang benötigt eine Semantik.");
    validateTransformations(output.postprocessing);
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
    for (const value of Object.values(transformation.parameters)) {
      if (!validParameter(value))
        throw new Error("Ein Transformationsparameter ist ungültig.");
    }
  }
}

function validParameter(value: TransformationParameter): boolean {
  if (typeof value === "number") return Number.isFinite(value);
  if (typeof value === "string" || typeof value === "boolean") return true;
  return value.every(validParameter);
}
