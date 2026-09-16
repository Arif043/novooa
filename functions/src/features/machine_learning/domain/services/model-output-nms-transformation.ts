import {type Transformation, type TransformationParameter} from "../entities/model-contract.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelOutputTransformationStrategy} from "./model-output-transformation-strategy.js";
import {type PostprocessingValue, requiredNumericTensor} from "./model-output-transformation-values.js";

export function nonMaximumSuppressionOutputTransformationStrategy(): ModelOutputTransformationStrategy {
  return {
    type: "tensor.nonMaximumSuppression",
    validate: (transformation) => {
      nmsParameters(transformation.parameters);
    },
    transform: (value, transformation) => nonMaximumSuppression(value, transformation),
  };
}

function nonMaximumSuppression(
  value: PostprocessingValue,
  transformation: Transformation,
): ModelOutputValue {
  if (transformation.type !== "tensor.nonMaximumSuppression") {
    throw new Error(`Die Ausgangstransformation ${transformation.type} wird nicht unterstützt.`);
  }
  const tensor = requiredNumericTensor(value, "tensor.nonMaximumSuppression");
  if (tensor.shape.length !== 2) {
    throw new Error("tensor.nonMaximumSuppression erwartet [erkennungen, werte].");
  }
  const parameters = nmsParameters(transformation.parameters);
  const width = tensor.shape[1]!;
  const detections = Array.from({length: tensor.shape[0]!},
    (_, row) => detectionAt(tensor.values, row, width, parameters))
    .filter((item): item is Detection => item !== null);
  return suppressOverlaps(detections, parameters.iouThreshold);
}

type NmsParameters = {
  readonly box: Readonly<Record<"left" | "top" | "right" | "bottom", number>>;
  readonly scoreIndex: number;
  readonly scoreThreshold: number;
  readonly iouThreshold: number;
};

type Detection = {
  readonly index: number;
  readonly score: number;
  readonly box: Readonly<Record<"left" | "top" | "right" | "bottom", number>>;
};

function nmsParameters(parameters: Readonly<Record<string, TransformationParameter>>): NmsParameters {
  const box = requiredRecord(parameters.box, "tensor.nonMaximumSuppression benötigt box.");
  const pairs = ["left", "top", "right", "bottom"].map((key) => [
    key,
    requiredNonNegativeInteger(box[key], "Die Box-Indizes müssen nichtnegative ganze Zahlen sein."),
  ]);
  return {
    box: Object.fromEntries(pairs) as NmsParameters["box"],
    scoreIndex: requiredNonNegativeInteger(parameters.scoreIndex, "tensor.nonMaximumSuppression benötigt scoreIndex."),
    scoreThreshold: optionalNumber(parameters.scoreThreshold, -Infinity),
    iouThreshold: boundedNumber(parameters.iouThreshold, 0.5, 0, 1),
  };
}

function detectionAt(
  values: readonly number[],
  row: number,
  width: number,
  parameters: NmsParameters,
): Detection | null {
  const indexes = [...Object.values(parameters.box), parameters.scoreIndex];
  if (indexes.some((index) => index >= width)) throw new Error("Ein Erkennungsindex liegt außerhalb der Tensorbreite.");
  const at = (index: number) => values[row * width + index]!;
  const score = at(parameters.scoreIndex);
  if (score < parameters.scoreThreshold) return null;
  const box = {
    left: at(parameters.box.left),
    top: at(parameters.box.top),
    right: at(parameters.box.right),
    bottom: at(parameters.box.bottom),
  };
  if (box.right < box.left || box.bottom < box.top) throw new Error("Eine Erkennungsbox ist ungültig.");
  return {index: row, score, box};
}

function suppressOverlaps(detections: readonly Detection[], iouThreshold: number): ModelOutputValue {
  const accepted: Detection[] = [];
  for (const candidate of [...detections].sort((left, right) => right.score - left.score)) {
    if (accepted.every((item) => iou(candidate.box, item.box) <= iouThreshold)) {
      accepted.push(candidate);
    }
  }
  return accepted.map((item) => ({index: item.index, score: item.score, box: item.box}));
}

function iou(left: Detection["box"], right: Detection["box"]): number {
  const overlapWidth = Math.max(0, Math.min(left.right, right.right) - Math.max(left.left, right.left));
  const overlapHeight = Math.max(0, Math.min(left.bottom, right.bottom) - Math.max(left.top, right.top));
  const overlap = overlapWidth * overlapHeight;
  const leftArea = (left.right - left.left) * (left.bottom - left.top);
  const rightArea = (right.right - right.left) * (right.bottom - right.top);
  return overlap / (leftArea + rightArea - overlap || 1);
}

function boundedNumber(
  value: TransformationParameter | undefined,
  fallback: number,
  minimum: number,
  maximum: number,
): number {
  const number = optionalNumber(value, fallback);
  if (number < minimum || number > maximum) throw new Error("Der Transformationsparameter liegt außerhalb des erlaubten Bereichs.");
  return number;
}

function optionalNumber(value: TransformationParameter | undefined, fallback: number): number {
  if (value === undefined) return fallback;
  if (typeof value !== "number" || !Number.isFinite(value)) throw new Error("Der Transformationsparameter ist ungültig.");
  return value;
}

function requiredNonNegativeInteger(value: TransformationParameter | undefined, message: string): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value < 0) throw new Error(message);
  return value;
}

function requiredRecord(
  value: TransformationParameter | undefined,
  message: string,
): Readonly<Record<string, TransformationParameter>> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) throw new Error(message);
  return value as Readonly<Record<string, TransformationParameter>>;
}
