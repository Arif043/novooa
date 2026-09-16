import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelTensor} from "../entities/model-tensor.js";

export type TensorPostprocessingValue = {
  readonly type: "tensor";
  readonly shape: readonly number[];
  readonly values: readonly (number | boolean)[];
};

export type PostprocessingValue = TensorPostprocessingValue | ModelOutputValue;

export type NumericTensorPostprocessingValue = Omit<TensorPostprocessingValue, "values"> & {
  readonly values: readonly number[];
};

type TensorReader = {
  readonly byteLength: number;
  readonly read: (view: DataView, offset: number) => number | boolean;
};

export function tensorValue(tensor: ModelTensor): TensorPostprocessingValue {
  const reader = readers[tensor.dataType];
  const view = new DataView(tensor.bytes.buffer, tensor.bytes.byteOffset, tensor.bytes.byteLength);
  const values = Array.from({length: tensor.bytes.byteLength / reader.byteLength},
    (_, index) => reader.read(view, index * reader.byteLength));
  return {type: "tensor", shape: tensor.shape, values};
}

export function isTensorValue(value: PostprocessingValue): value is TensorPostprocessingValue {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    && "type" in value && value.type === "tensor";
}

export function requiredTensor(value: PostprocessingValue, transformation: string): TensorPostprocessingValue {
  if (!isTensorValue(value)) throw new Error(`${transformation} benötigt einen Tensor.`);
  return value;
}

export function requiredNumericTensor(
  value: PostprocessingValue,
  transformation: string,
): NumericTensorPostprocessingValue {
  const tensor = requiredTensor(value, transformation);
  if (tensor.values.some((item) => typeof item !== "number")) {
    throw new Error(`${transformation} benötigt numerische Werte.`);
  }
  return tensor as NumericTensorPostprocessingValue;
}

export function workflowValueFor(value: PostprocessingValue): ModelOutputValue {
  return isTensorValue(value) ? nestedValues(value.values, value.shape) : value;
}

function nestedValues(
  values: readonly (number | boolean)[],
  shape: readonly number[],
  offset = 0,
): ModelOutputValue {
  if (shape.length === 1) return values.slice(offset, offset + shape[0]) as readonly ModelOutputValue[];
  const childLength = shape.slice(1).reduce((total, dimension) => total * dimension, 1);
  return Array.from({length: shape[0]},
    (_, index) => nestedValues(values, shape.slice(1), offset + index * childLength));
}

const readers: Readonly<Record<ModelTensor["dataType"], TensorReader>> = {
  float32: {byteLength: 4, read: (view, offset) => view.getFloat32(offset, true)},
  float64: {byteLength: 8, read: (view, offset) => view.getFloat64(offset, true)},
  int64: {byteLength: 8, read: (view, offset) => Number(view.getBigInt64(offset, true))},
  int32: {byteLength: 4, read: (view, offset) => view.getInt32(offset, true)},
  int16: {byteLength: 2, read: (view, offset) => view.getInt16(offset, true)},
  int8: {byteLength: 1, read: (view, offset) => view.getInt8(offset)},
  uint8: {byteLength: 1, read: (view, offset) => view.getUint8(offset)},
  bool: {byteLength: 1, read: (view, offset) => view.getUint8(offset) !== 0},
};
