import {type ModelOutput} from "../entities/model-contract.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelTensor} from "../entities/model-tensor.js";
import {mapWorkflowOutput} from "./workflow-output-mapper.js";
import {type OutputParameterValue} from "./model-output-numeric-transformations.js";
import {defaultModelOutputTransformationStrategies} from "./default-model-output-transformation-strategies.js";
import {ModelOutputTransformationRegistry} from "./model-output-transformation-registry.js";
import {type PostprocessingValue, tensorValue, workflowValueFor} from "./model-output-transformation-values.js";

export type ModelOutputParameterValue = OutputParameterValue;

export type ProcessedModelOutput = {
  readonly workflowOutput: ModelOutput["workflowOutput"];
  readonly value: ModelOutputValue;
};

export class ModelOutputPostprocessor {
  constructor(
    private readonly transformations = new ModelOutputTransformationRegistry(
      defaultModelOutputTransformationStrategies(),
    ),
  ) {}

  process(
    output: ModelOutput,
    tensor: ModelTensor,
    parameterValues: readonly ModelOutputParameterValue[],
  ): ProcessedModelOutput {
    validateModelOutputPostprocessing(output, this.transformations);
    const values = new Map<string, ModelOutputValue>();
    let current: PostprocessingValue = tensorValue(tensor);
    values.set("tensor", workflowValueFor(current));
    for (const transformation of output.transformations) {
      current = this.transformations.transform(current, transformation, {
        outputName: output.name,
        parameterValues,
      });
      storeTransformationValue(values, transformation.result, workflowValueFor(current));
    }
    return {
      workflowOutput: output.workflowOutput,
      value: mapWorkflowOutput(output.workflowOutput.mapping, values),
    };
  }
}

export function validateModelOutputPostprocessing(
  output: ModelOutput,
  transformations = new ModelOutputTransformationRegistry(
    defaultModelOutputTransformationStrategies(),
  ),
): void {
  output.transformations.forEach((transformation) => transformations.validate(transformation));
}

function storeTransformationValue(
  values: Map<string, ModelOutputValue>,
  result: string | undefined,
  value: ModelOutputValue,
): void {
  values.set("tensor", value);
  if (result !== undefined) values.set(result, value);
}
