import {type Transformation, type TransformationParameter} from "../entities/model-contract.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelOutputTransformationStrategy} from "./model-output-transformation-strategy.js";
import {type PostprocessingValue, requiredTensor} from "./model-output-transformation-values.js";

export function connectedComponentsOutputTransformationStrategy(): ModelOutputTransformationStrategy {
  return {
    type: "mask.connectedComponents",
    validate: (transformation) => {
      nonNegativeInteger(transformation.parameters.minimumPixels, 1);
    },
    transform: (value, transformation) => connectedComponents(value, transformation),
  };
}

function connectedComponents(value: PostprocessingValue, transformation: Transformation): ModelOutputValue {
  const tensor = requiredTensor(value, "mask.connectedComponents");
  const [height, width] = imageDimensions(tensor.shape);
  const mask = tensor.values.map((item) => item === true);
  return regionsFromMask(mask, width, height, nonNegativeInteger(transformation.parameters.minimumPixels, 1));
}

function regionsFromMask(mask: readonly boolean[], width: number, height: number, minimumPixels: number): ModelOutputValue {
  const visited = new Set<number>();
  const regions: ModelOutputValue[] = [];
  mask.forEach((pixel, index) => {
    if (!pixel || visited.has(index)) return;
    const region = regionFrom(mask, index, width, height, visited);
    if (region.pixelCount >= minimumPixels) regions.push(region);
  });
  return regions;
}

type Region = {
  readonly bounds: Readonly<Record<"left" | "top" | "width" | "height", number>>;
  readonly pixelCount: number;
};

function regionFrom(mask: readonly boolean[], first: number, width: number, height: number, visited: Set<number>): Region {
  const pending = [first];
  let left = width;
  let right = 0;
  let top = height;
  let bottom = 0;
  let pixelCount = 0;
  while (pending.length > 0) {
    const index = pending.pop()!;
    if (visited.has(index) || !mask[index]) continue;
    visited.add(index);
    const x = index % width;
    const y = Math.floor(index / width);
    left = Math.min(left, x);
    right = Math.max(right, x);
    top = Math.min(top, y);
    bottom = Math.max(bottom, y);
    pixelCount++;
    neighbours(x, y, width, height).forEach((item) => pending.push(item));
  }
  return {bounds: {left, top, width: right - left + 1, height: bottom - top + 1}, pixelCount};
}

function neighbours(x: number, y: number, width: number, height: number): readonly number[] {
  return [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]]
    .filter(([nextX, nextY]) => nextX >= 0 && nextX < width && nextY >= 0 && nextY < height)
    .map(([nextX, nextY]) => nextY * width + nextX);
}

function imageDimensions(shape: readonly number[]): readonly [number, number] {
  if (shape.length < 2 || shape.slice(0, -2).some((size) => size !== 1)) {
    throw new Error("mask.connectedComponents erwartet eine einzelne zweidimensionale Maske.");
  }
  return [shape[shape.length - 2]!, shape[shape.length - 1]!];
}

function nonNegativeInteger(value: TransformationParameter | undefined, fallback: number): number {
  if (value === undefined) return fallback;
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value < 0) {
    throw new Error("Der Transformationsparameter muss eine nichtnegative ganze Zahl sein.");
  }
  return value;
}
