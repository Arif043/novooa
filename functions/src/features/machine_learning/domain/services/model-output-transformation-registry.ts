import {type Transformation} from "../entities/model-contract.js";
import {type PostprocessingValue} from "./model-output-transformation-values.js";
import {
  type ModelOutputTransformationContext,
  type ModelOutputTransformationStrategy,
} from "./model-output-transformation-strategy.js";

export class ModelOutputTransformationRegistry {
  private readonly strategies: ReadonlyMap<string, ModelOutputTransformationStrategy>;

  constructor(strategies: readonly ModelOutputTransformationStrategy[]) {
    this.strategies = strategyMap(strategies);
  }

  validate(transformation: Transformation): void {
    this.strategyFor(transformation).validate(transformation);
  }

  transform(
    value: PostprocessingValue,
    transformation: Transformation,
    context: ModelOutputTransformationContext,
  ): PostprocessingValue {
    return this.strategyFor(transformation).transform(value, transformation, context);
  }

  private strategyFor(transformation: Transformation): ModelOutputTransformationStrategy {
    const strategy = this.strategies.get(transformation.type);
    if (strategy === undefined) {
      throw new Error(`Die Ausgangstransformation ${transformation.type} wird nicht unterstützt.`);
    }
    return strategy;
  }
}

function strategyMap(
  strategies: readonly ModelOutputTransformationStrategy[],
): ReadonlyMap<string, ModelOutputTransformationStrategy> {
  const values = new Map(strategies.map((strategy) => [strategy.type, strategy]));
  if (values.size !== strategies.length) {
    throw new Error("Ausgabetransformationen dürfen nur einmal registriert werden.");
  }
  return values;
}
