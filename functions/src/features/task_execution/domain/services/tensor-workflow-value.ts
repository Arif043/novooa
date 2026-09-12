import {type ModelInferenceOutput} from
  "../../../machine_learning/domain/repositories/model-inference.js";

export function workflowValueForTensor(output: ModelInferenceOutput): unknown {
  const values = valuesFor(output);
  return nestedValues(values, output.shape);
}

function valuesFor(output: ModelInferenceOutput): readonly (number | boolean)[] {
  const view = new DataView(
    output.bytes.buffer,
    output.bytes.byteOffset,
    output.bytes.byteLength,
  );
  const reader = readerFor(output.dataType);
  return Array.from(
    {length: output.bytes.byteLength / reader.byteLength},
    (_, index) => reader.read(view, index * reader.byteLength),
  );
}

function nestedValues(
  values: readonly (number | boolean)[],
  shape: readonly number[],
  offset = 0,
): unknown {
  if (shape.length === 1) return values.slice(offset, offset + shape[0]);
  const childLength = elementCount(shape.slice(1));
  return Array.from(
    {length: shape[0]},
    (_, index) => nestedValues(values, shape.slice(1), offset + index * childLength),
  );
}

function elementCount(shape: readonly number[]): number {
  return shape.reduce((count, dimension) => count * dimension, 1);
}

type TensorReader = {
  byteLength: number;
  read: (view: DataView, offset: number) => number | boolean;
};

function readerFor(dataType: ModelInferenceOutput["dataType"]): TensorReader {
  return readers[dataType];
}

const readers: Readonly<Record<ModelInferenceOutput["dataType"], TensorReader>> = {
  float32: {byteLength: 4, read: (view, offset) => view.getFloat32(offset, true)},
  float64: {byteLength: 8, read: (view, offset) => view.getFloat64(offset, true)},
  int64: {byteLength: 8, read: (view, offset) => Number(view.getBigInt64(offset, true))},
  int32: {byteLength: 4, read: (view, offset) => view.getInt32(offset, true)},
  int16: {byteLength: 2, read: (view, offset) => view.getInt16(offset, true)},
  int8: {byteLength: 1, read: (view, offset) => view.getInt8(offset)},
  uint8: {byteLength: 1, read: (view, offset) => view.getUint8(offset)},
  bool: {byteLength: 1, read: (view, offset) => view.getUint8(offset) !== 0},
};
