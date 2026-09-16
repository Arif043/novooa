import {type Transformation, type TransformationParameter} from "../entities/model-contract.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelOutputTransformationStrategy} from "./model-output-transformation-strategy.js";
import {type PostprocessingValue, requiredNumericTensor} from "./model-output-transformation-values.js";

export function ctcGreedyDecodeOutputTransformationStrategy(): ModelOutputTransformationStrategy {
  return {
    type: "sequence.ctcGreedyDecode",
    validate: (transformation) => {
      ctcParameters(transformation.parameters);
    },
    transform: (value, transformation) => ctcGreedyDecode(value, transformation),
  };
}

function ctcGreedyDecode(
  value: PostprocessingValue,
  transformation: Transformation,
): ModelOutputValue {
  if (transformation.type !== "sequence.ctcGreedyDecode") {
    throw new Error(`Die Ausgangstransformation ${transformation.type} wird nicht unterstützt.`);
  }
  const tensor = requiredNumericTensor(value, "sequence.ctcGreedyDecode");
  const parameters = ctcParameters(transformation.parameters);
  const [batchSize, timeSteps, classCount] = sequenceDimensions(tensor.shape);
  if (parameters.labels.length !== classCount) {
    throw new Error("Die CTC-Labels müssen zur letzten Tensorachse passen.");
  }
  return Array.from({length: batchSize}, (_, index) => {
    const start = index * timeSteps * classCount;
    return decodedSequence(tensor.values.slice(start, start + timeSteps * classCount), classCount, parameters);
  });
}

type CtcParameters = {
  readonly labels: readonly string[];
  readonly blankIndex: number;
  readonly applySoftmax: boolean;
  readonly collapseRepeated: boolean;
};

function ctcParameters(
  parameters: Readonly<Record<string, TransformationParameter>>,
): CtcParameters {
  const labels = requiredStringList(parameters.labels, "sequence.ctcGreedyDecode benötigt labels.");
  const blankIndex = requiredNonNegativeInteger(parameters.blankIndex, "sequence.ctcGreedyDecode benötigt blankIndex.");
  if (blankIndex >= labels.length) throw new Error("Der CTC-Leerindex ist ungültig.");
  return {
    labels,
    blankIndex,
    applySoftmax: optionalBoolean(parameters.applySoftmax, true),
    collapseRepeated: optionalBoolean(parameters.collapseRepeated, true),
  };
}

function sequenceDimensions(shape: readonly number[]): readonly [number, number, number] {
  if (shape.length === 2) return [1, shape[0]!, shape[1]!];
  if (shape.length === 3) return [shape[0]!, shape[1]!, shape[2]!];
  throw new Error("sequence.ctcGreedyDecode erwartet [zeit, klassen] oder [batch, zeit, klassen].");
}

function decodedSequence(
  values: readonly number[],
  classCount: number,
  parameters: CtcParameters,
): Readonly<Record<string, ModelOutputValue>> {
  let previous = -1;
  let count = 0;
  let logProbability = 0;
  let text = "";
  for (let offset = 0; offset < values.length; offset += classCount) {
    const probabilities = parameters.applySoftmax
      ? softmax(values.slice(offset, offset + classCount))
      : values.slice(offset, offset + classCount);
    const index = maximumIndex(probabilities);
    if (index !== parameters.blankIndex && (!parameters.collapseRepeated || index !== previous)) {
      text += parameters.labels[index]!;
      logProbability += Math.log(Math.max(probabilities[index]!, Number.MIN_VALUE));
      count++;
    }
    previous = index;
  }
  return {text, confidence: count === 0 ? 0 : Math.exp(logProbability / count)};
}

function softmax(values: readonly number[]): readonly number[] {
  const maximum = Math.max(...values);
  const exponentials = values.map((item) => Math.exp(item - maximum));
  const sum = exponentials.reduce((total, item) => total + item, 0);
  return exponentials.map((item) => item / sum);
}

function maximumIndex(values: readonly number[]): number {
  return values.reduce((best, item, index) => item > values[best]! ? index : best, 0);
}

function requiredStringList(
  value: TransformationParameter | undefined,
  message: string,
): readonly string[] {
  if (!Array.isArray(value) || value.some((item) => typeof item !== "string")) throw new Error(message);
  return value;
}

function requiredNonNegativeInteger(
  value: TransformationParameter | undefined,
  message: string,
): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value < 0) throw new Error(message);
  return value;
}

function optionalBoolean(value: TransformationParameter | undefined, fallback: boolean): boolean {
  if (value === undefined) return fallback;
  if (typeof value !== "boolean") throw new Error("Der Transformationsparameter muss ein Boolean sein.");
  return value;
}
