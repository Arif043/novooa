import {type ModelOutputTransformationStrategy} from "./model-output-transformation-strategy.js";
import {ctcGreedyDecodeOutputTransformationStrategy} from "./model-output-ctc-transformations.js";
import {nonMaximumSuppressionOutputTransformationStrategy} from "./model-output-nms-transformation.js";
import {numericOutputTransformationStrategies} from "./model-output-numeric-transformations.js";
import {connectedComponentsOutputTransformationStrategy} from "./model-output-vision-transformations.js";

export function defaultModelOutputTransformationStrategies(): readonly ModelOutputTransformationStrategy[] {
  return [
    ...numericOutputTransformationStrategies(),
    connectedComponentsOutputTransformationStrategy(),
    nonMaximumSuppressionOutputTransformationStrategy(),
    ctcGreedyDecodeOutputTransformationStrategy(),
  ];
}
