import {
  type ModelContract,
  type ModelInput,
  type ModelInputSourceType,
  type ModelOutput,
  type ModelTensorDataType,
  type TensorDimension,
  type Transformation,
  type TransformationParameter,
  modelTensorDataTypes,
  modelInputSourceTypes,
  validateModelContract,
} from "../domain/entities/model-contract.js";

export function modelContractFromUnknown(value: unknown): ModelContract {
  const data = recordFrom(value, "Der Modellvertrag ist ungültig.");
  const contract = {
    inputs: listFrom(data.inputs, inputFrom),
    outputs: listFrom(data.outputs, outputFrom),
  };
  validateModelContract(contract);
  return contract;
}

function inputFrom(value: unknown): ModelInput {
  const data = recordFrom(value, "Der Modelleingang ist ungültig.");
  return {
    ...tensorFrom(data),
    source: inputSourceFrom(data.source),
    preprocessing: listFrom(data.preprocessing, transformationFrom),
  };
}

function outputFrom(value: unknown): ModelOutput {
  const data = recordFrom(value, "Der Modellausgang ist ungültig.");
  return {
    ...tensorFrom(data),
    semantic: stringFrom(data.semantic, "Die Ausgangssemantik fehlt."),
    postprocessing: listFrom(data.postprocessing, transformationFrom),
  };
}

function tensorFrom(data: Record<string, unknown>) {
  return {
    name: stringFrom(data.name, "Der Tensor-Name fehlt."),
    dataType: dataTypeFrom(data.dataType),
    shape: listFrom(data.shape, dimensionFrom),
  };
}

function transformationFrom(value: unknown): Transformation {
  const data = recordFrom(value, "Die Transformation ist ungültig.");
  return {
    type: stringFrom(data.type, "Der Transformationstyp fehlt."),
    parameters: parametersFrom(data.parameters),
  };
}

function parametersFrom(
  value: unknown,
): Readonly<Record<string, TransformationParameter>> {
  const parameters = recordFrom(
    value,
    "Die Transformationsparameter sind ungültig.",
  );
  return Object.fromEntries(
    Object.entries(parameters).map(([key, item]) => [key, parameterFrom(item)]),
  );
}

function parameterFrom(value: unknown): TransformationParameter {
  if (typeof value === "string" || typeof value === "boolean") return value;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (Array.isArray(value)) return value.map(parameterFrom);
  throw new Error("Ein Transformationsparameter ist ungültig.");
}

function dataTypeFrom(value: unknown): ModelTensorDataType {
  if (
    typeof value === "string" &&
    modelTensorDataTypes.includes(value as ModelTensorDataType)
  ) {
    return value as ModelTensorDataType;
  }
  throw new Error("Der Tensor-Datentyp ist ungültig.");
}

function dimensionFrom(value: unknown): TensorDimension {
  if (value === "dynamic") return value;
  if (typeof value === "number" && Number.isSafeInteger(value) && value > 0)
    return value;
  throw new Error("Eine Tensor-Dimension ist ungültig.");
}

function inputSourceFrom(value: unknown): ModelInputSourceType {
  if (typeof value === "string" && modelInputSourceTypes.includes(value as ModelInputSourceType)) {
    return value as ModelInputSourceType;
  }
  throw new Error("Die Eingabequelle ist ungültig.");
}

function listFrom<T>(
  value: unknown,
  itemFrom: (item: unknown) => T,
): readonly T[] {
  if (!Array.isArray(value))
    throw new Error("Eine Modellvertrag-Liste ist ungültig.");
  return value.map(itemFrom);
}

function recordFrom(value: unknown, message: string): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(message);
  }
  return value as Record<string, unknown>;
}

function stringFrom(value: unknown, message: string): string {
  if (typeof value !== "string" || value.trim().length === 0)
    throw new Error(message);
  return value;
}
