import {
  type ModelOutput,
  type Transformation,
  type TransformationParameter,
} from "../entities/model-contract.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelTensor} from "../entities/model-tensor.js";
import {mapWorkflowOutput} from "./workflow-output-mapper.js";
export type ModelOutputParameterValue = {
  outputName: string;
  name: string;
  value: number;
};
export type ProcessedModelOutput = {
  workflowOutput: ModelOutput["workflowOutput"];
  value: ModelOutputValue;
};
type TensorValue = {
  type: "tensor";
  shape: readonly number[];
  values: readonly (number | boolean)[];
};

type TopValue = {index: number; value: number};
type PostprocessingValue = TensorValue | readonly TopValue[];
export class ModelOutputPostprocessor {
  process(
    output: ModelOutput,
    tensor: ModelTensor,
    parameterValues: readonly ModelOutputParameterValue[],
  ): ProcessedModelOutput {
    validateModelOutputPostprocessing(output);
    const values = new Map<string, ModelOutputValue>();
    let current: PostprocessingValue = tensorValue(tensor);
    values.set("tensor", workflowValueFor(current));
    for (const transformation of output.postprocessing) {
      current = transformed(current, transformation, output.name, parameterValues);
      valuesForTransformation(values, transformation, current);
    }
    return {
      workflowOutput: output.workflowOutput,
      value: mapWorkflowOutput(output.workflowOutput.mapping, values),
    };
  }
}
export function validateModelOutputPostprocessing(output: ModelOutput): void {
  for (const transformation of output.postprocessing) {
    if (transformation.type === "tensor.softmax") {
      optionalNumber(transformation.parameters.axis, -1);
      continue;
    }
    if (transformation.type === "tensor.topK") {
      parameterDescriptor(transformation.parameters.parameter);
      continue;
    }
    throw new Error(`Die Ausgangstransformation ${transformation.type} wird nicht unterstützt.`);
  }
}

function tensorValue(tensor: ModelTensor): TensorValue {
  const reader = readers[tensor.dataType];
  const view = new DataView(tensor.bytes.buffer, tensor.bytes.byteOffset, tensor.bytes.byteLength);
  const values = Array.from({length: tensor.bytes.byteLength / reader.byteLength},
    (_, index) => reader.read(view, index * reader.byteLength));
  return {type: "tensor", shape: tensor.shape, values};
}

function transformed(
  current: PostprocessingValue,
  transformation: Transformation,
  outputName: string,
  parameterValues: readonly ModelOutputParameterValue[],
): PostprocessingValue {
  if (transformation.type === "tensor.softmax") return softmax(current, transformation);
  if (transformation.type === "tensor.topK") return topK(current, transformation, outputName, parameterValues);
  throw new Error(`Die Ausgangstransformation ${transformation.type} wird nicht unterstützt.`);
}

function softmax(current: PostprocessingValue, transformation: Transformation): TensorValue {
  const tensor = requiredTensor(current, "tensor.softmax");
  const axis = optionalNumber(transformation.parameters.axis, -1);
  if (axis !== -1) throw new Error("tensor.softmax unterstützt nur die letzte Tensorachse.");
  if (tensor.values.some((value) => typeof value !== "number")) throw new Error("tensor.softmax benötigt einen numerischen Tensor.");
  const width = tensor.shape[tensor.shape.length - 1]!;
  const values = tensor.values as readonly number[];
  return {type: "tensor", shape: tensor.shape, values: Array.from(
    {length: values.length / width},
    (_, batch) => softmaxVector(values.slice(batch * width, (batch + 1) * width)),
  ).flat()};
}

function softmaxVector(values: readonly number[]): readonly number[] {
  const maximum = Math.max(...values);
  const exponentials = values.map((value) => Math.exp(value - maximum));
  const sum = exponentials.reduce((total, value) => total + value, 0);
  return exponentials.map((value) => value / sum);
}

function topK(
  current: PostprocessingValue,
  transformation: Transformation,
  outputName: string,
  parameterValues: readonly ModelOutputParameterValue[],
): readonly TopValue[] {
  const tensor = requiredTensor(current, "tensor.topK");
  if (tensor.shape.length > 1 && tensor.shape.slice(0, -1).reduce((count, size) => count * size, 1) !== 1) {
    throw new Error("tensor.topK unterstützt nur einzelne Vektoren.");
  }
  if (tensor.values.some((value) => typeof value !== "number")) throw new Error("tensor.topK benötigt numerische Werte.");
  const count = selectedCount(transformation.parameters.parameter, outputName, parameterValues);
  return (tensor.values as readonly number[]).map((value, index) => ({index, value}))
    .sort((left, right) => right.value - left.value).slice(0, count);
}

function selectedCount(
  value: TransformationParameter | undefined,
  outputName: string,
  parameterValues: readonly ModelOutputParameterValue[],
): number {
  const descriptor = parameterDescriptor(value);
  const selected = parameterValues.find((item) => item.outputName === outputName && item.name === descriptor.name);
  const count = selected?.value ?? descriptor.defaultValue;
  if (!Number.isSafeInteger(count) || count < descriptor.minimum || count > descriptor.maximum) {
    throw new Error(`Der Parameter ${descriptor.name} liegt außerhalb des erlaubten Bereichs.`);
  }
  return count;
}

function valuesForTransformation(
  values: Map<string, ModelOutputValue>,
  transformation: Transformation,
  current: PostprocessingValue,
): void {
  const workflowValue = workflowValueFor(current);
  values.set("tensor", workflowValue);
  if (transformation.result !== undefined) values.set(transformation.result, workflowValue);
}

function workflowValueFor(value: PostprocessingValue): ModelOutputValue {
  if (isTensorValue(value)) return nestedValues(value.values, value.shape);
  return value.map((item) => ({index: item.index, value: item.value}));
}

function nestedValues(values: readonly (number | boolean)[], shape: readonly number[], offset = 0): ModelOutputValue {
  if (shape.length === 1) return values.slice(offset, offset + shape[0]) as readonly ModelOutputValue[];
  const childLength = shape.slice(1).reduce((count, dimension) => count * dimension, 1);
  return Array.from({length: shape[0]}, (_, index) => nestedValues(values, shape.slice(1), offset + index * childLength));
}

function requiredTensor(value: PostprocessingValue, transformation: string): TensorValue {
  if (!isTensorValue(value)) throw new Error(`${transformation} benötigt einen Tensor.`);
  return value;
}

function isTensorValue(value: PostprocessingValue): value is TensorValue {
  return !Array.isArray(value);
}

function parameterDescriptor(value: TransformationParameter | undefined) {
  if (!isRecord(value)) throw new Error("tensor.topK benötigt eine Parameterbeschreibung.");
  const name = requiredText(value.name, "Der Name des Ausgangsparameters fehlt.");
  const defaultValue = requiredInteger(value.default, "Der Standardwert des Ausgangsparameters ist ungültig.");
  const minimum = requiredInteger(value.minimum, "Der Minimalwert des Ausgangsparameters ist ungültig.");
  const maximum = requiredInteger(value.maximum, "Der Maximalwert des Ausgangsparameters ist ungültig.");
  if (minimum > defaultValue || defaultValue > maximum) throw new Error("Der Bereich des Ausgangsparameters ist ungültig.");
  return {name, defaultValue, minimum, maximum};
}

function optionalNumber(value: TransformationParameter | undefined, fallback: number): number {
  if (value === undefined) return fallback;
  if (typeof value !== "number" || !Number.isFinite(value)) throw new Error("Der Transformationsparameter ist ungültig.");
  return value;
}

function requiredInteger(value: TransformationParameter | undefined, message: string): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value)) throw new Error(message);
  return value;
}

function requiredText(value: TransformationParameter | undefined, message: string): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new Error(message);
  return value;
}

function isRecord(value: TransformationParameter | undefined): value is Readonly<Record<string, TransformationParameter>> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

type TensorReader = {byteLength: number; read: (view: DataView, offset: number) => number | boolean};

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
