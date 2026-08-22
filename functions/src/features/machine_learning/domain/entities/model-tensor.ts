import {
  type ModelTensorDataType,
  type Tensor,
} from "./model-contract.js";

export type ModelTensor = {
  name: string;
  dataType: ModelTensorDataType;
  shape: readonly number[];
  bytes: Uint8Array;
};

const bytesPerElement: Readonly<Record<ModelTensorDataType, number>> = {
  float32: 4,
  float64: 8,
  int64: 8,
  int32: 4,
  int16: 2,
  int8: 1,
  uint8: 1,
  bool: 1,
};

export function validateModelTensor(tensor: ModelTensor): void {
  validName(tensor.name);
  validShape(tensor.shape, tensor.name);
  validByteLength(tensor);
}

export function validateTensorsForContract(
  tensors: readonly ModelTensor[],
  definitions: readonly Tensor[],
  kind: string,
): void {
  const tensorsByName = uniqueTensorMap(tensors, kind);
  requiredNames(tensorsByName, definitions, kind);
  definitions.forEach((definition) => {
    tensorMatchesDefinition(tensorsByName.get(definition.name)!, definition, kind);
  });
}

function uniqueTensorMap(
  tensors: readonly ModelTensor[],
  kind: string,
): ReadonlyMap<string, ModelTensor> {
  tensors.forEach(validateModelTensor);
  const tensorsByName = new Map(tensors.map((tensor) => [tensor.name, tensor]));
  if (tensorsByName.size !== tensors.length) {
    throw new Error(`${kind}-Tensoren dürfen keine doppelten Namen haben.`);
  }
  return tensorsByName;
}

function requiredNames(
  tensors: ReadonlyMap<string, ModelTensor>,
  definitions: readonly Tensor[],
  kind: string,
): void {
  if (tensors.size !== definitions.length) {
    throw new Error(`${kind}-Tensoren stimmen nicht mit dem Modellvertrag überein.`);
  }
  if (definitions.some((definition) => !tensors.has(definition.name))) {
    throw new Error(`${kind}-Tensoren stimmen nicht mit dem Modellvertrag überein.`);
  }
}

function tensorMatchesDefinition(
  tensor: ModelTensor,
  definition: Tensor,
  kind: string,
): void {
  if (tensor.dataType !== definition.dataType || !shapeMatches(tensor.shape, definition.shape)) {
    throw new Error(`${kind}-Tensor ${definition.name} stimmt nicht mit dem Modellvertrag überein.`);
  }
}

function shapeMatches(
  shape: readonly number[],
  definition: readonly (number | "dynamic")[],
): boolean {
  return shape.length === definition.length && shape.every((value, index) => {
    const expected = definition[index];
    return expected === "dynamic" || expected === value;
  });
}

function validName(name: string): void {
  if (name.trim().length === 0) throw new Error("Der Tensor-Name fehlt.");
}

function validShape(shape: readonly number[], name: string): void {
  if (shape.length === 0 || !shape.every(validDimension)) {
    throw new Error(`Die Tensor-Form von ${name} ist ungültig.`);
  }
}

function validDimension(dimension: number): boolean {
  return Number.isSafeInteger(dimension) && dimension > 0;
}

function validByteLength(tensor: ModelTensor): void {
  const expected = elementCount(tensor.shape) * bytesPerElement[tensor.dataType];
  if (tensor.bytes.byteLength !== expected) {
    throw new Error(`Die Byte-Länge von Tensor ${tensor.name} ist ungültig.`);
  }
}

function elementCount(shape: readonly number[]): number {
  return shape.reduce((count, dimension) => {
    if (count > Number.MAX_SAFE_INTEGER / dimension) {
      throw new Error("Der Tensor ist zu groß.");
    }
    return count * dimension;
  }, 1);
}
