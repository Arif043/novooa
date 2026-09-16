import {type Transformation} from "../entities/model-contract.js";
import {type PostprocessingValue} from "./model-output-transformation-values.js";

export type ModelOutputTransformationContext = {
  readonly outputName: string;
  readonly parameterValues: readonly {
    readonly outputName: string;
    readonly name: string;
    readonly value: number;
  }[];
};

export interface ModelOutputTransformationStrategy {
  readonly type: string;
  validate(transformation: Transformation): void;
  transform(
    value: PostprocessingValue,
    transformation: Transformation,
    context: ModelOutputTransformationContext,
  ): PostprocessingValue;
}
