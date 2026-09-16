import {type Transformation, type TransformationParameter} from "../entities/model-contract.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelOutputTransformationStrategy} from "./model-output-transformation-strategy.js";
import {
  type PostprocessingValue,
  type NumericTensorPostprocessingValue,
  type TensorPostprocessingValue,
  requiredNumericTensor,
} from "./model-output-transformation-values.js";

export type OutputParameterValue = {
  readonly outputName: string;
  readonly name: string;
  readonly value: number;
};

export function numericOutputTransformationStrategies(): readonly ModelOutputTransformationStrategy[] {
  return [
    strategy("tensor.softmax", validateSoftmax, (value, transformation) => softmax(value, transformation)),
    strategy("tensor.sigmoid", () => undefined, (value) => sigmoid(value)),
    strategy("tensor.threshold", validateThreshold, (value, transformation) => threshold(value, transformation)),
    strategy("tensor.topK", validateTopK, (value, transformation, context) => topK(
      value,
      transformation,
      context.outputName,
      context.parameterValues,
    )),
  ];
}

function strategy(
  type: string,
  validate: (transformation: Transformation) => void,
  transform: ModelOutputTransformationStrategy["transform"],
): ModelOutputTransformationStrategy {
  return {type, validate, transform};
}

function validateSoftmax(transformation: Transformation): void {
  optionalNumber(transformation.parameters.axis, -1);
}

function validateThreshold(transformation: Transformation): void {
  optionalNumber(transformation.parameters.value, 0.5);
}

function validateTopK(transformation: Transformation): void {
  parameterDescriptor(transformation.parameters.parameter);
}

function softmax(value: PostprocessingValue, transformation: Transformation): NumericTensorPostprocessingValue {
  const tensor = requiredNumericTensor(value, "tensor.softmax");
  const axis = optionalNumber(transformation.parameters.axis, -1);
  if (axis !== -1) throw new Error("tensor.softmax unterstützt nur die letzte Tensorachse.");
  const width = tensor.shape[tensor.shape.length - 1]!;
  const values = Array.from({length: tensor.values.length / width},
    (_, index) => softmaxVector(tensor.values.slice(index * width, (index + 1) * width))).flat();
  return {type: "tensor", shape: tensor.shape, values};
}

function sigmoid(value: PostprocessingValue): TensorPostprocessingValue {
  const tensor = requiredNumericTensor(value, "tensor.sigmoid");
  return {type: "tensor", shape: tensor.shape, values: tensor.values.map((item) => 1 / (1 + Math.exp(-item)))};
}

function threshold(value: PostprocessingValue, transformation: Transformation): TensorPostprocessingValue {
  const tensor = requiredNumericTensor(value, "tensor.threshold");
  const thresholdValue = optionalNumber(transformation.parameters.value, 0.5);
  return {type: "tensor", shape: tensor.shape, values: tensor.values.map((item) => item >= thresholdValue)};
}

function topK(
  value: PostprocessingValue,
  transformation: Transformation,
  outputName: string,
  parameterValues: readonly OutputParameterValue[],
): ModelOutputValue {
  const tensor = requiredNumericTensor(value, "tensor.topK");
  if (tensor.shape.length > 1 && tensor.shape.slice(0, -1).reduce(product, 1) !== 1) {
    throw new Error("tensor.topK unterstützt nur einzelne Vektoren.");
  }
  const count = selectedCount(transformation.parameters.parameter, outputName, parameterValues);
  return tensor.values.map((item, index) => ({index, value: item}))
    .sort((left, right) => right.value - left.value)
    .slice(0, count);
}

function softmaxVector(values: readonly number[]): readonly number[] {
  const maximum = Math.max(...values);
  const exponentials = values.map((item) => Math.exp(item - maximum));
  const sum = exponentials.reduce((total, item) => total + item, 0);
  return exponentials.map((item) => item / sum);
}

function selectedCount(
  value: TransformationParameter | undefined,
  outputName: string,
  parameterValues: readonly OutputParameterValue[],
): number {
  const descriptor = parameterDescriptor(value);
  const parameter = parameterValues.find(
    (item) => item.outputName === outputName && item.name === descriptor.name,
  );
  const count = parameter?.value ?? descriptor.defaultValue;
  if (!Number.isSafeInteger(count) || count < descriptor.minimum || count > descriptor.maximum) {
    throw new Error(`Der Parameter ${descriptor.name} liegt außerhalb des erlaubten Bereichs.`);
  }
  return count;
}

function parameterDescriptor(value: TransformationParameter | undefined) {
  const record = requiredRecord(value, "tensor.topK benötigt eine Parameterbeschreibung.");
  const name = requiredText(record.name, "Der Name des Ausgangsparameters fehlt.");
  const defaultValue = requiredInteger(record.default, "Der Standardwert des Ausgangsparameters ist ungültig.");
  const minimum = requiredInteger(record.minimum, "Der Minimalwert des Ausgangsparameters ist ungültig.");
  const maximum = requiredInteger(record.maximum, "Der Maximalwert des Ausgangsparameters ist ungültig.");
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

function requiredRecord(
  value: TransformationParameter | undefined,
  message: string,
): Readonly<Record<string, TransformationParameter>> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) throw new Error(message);
  return value as Readonly<Record<string, TransformationParameter>>;
}

function product(total: number, dimension: number): number {
  return total * dimension;
}
