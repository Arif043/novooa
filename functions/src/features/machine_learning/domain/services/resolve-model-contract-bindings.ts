import {
  type ModelContract,
  type TransformationParameter,
  type TransformationParameterRecord,
} from "../entities/model-contract.js";

const bindingPattern = /^\$([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*|\.\d+)*)$/;

export function resolveModelContractBindings(
  contract: ModelContract,
  bindings: Readonly<Record<string, unknown>> = {},
): ModelContract {
  return {
    inputs: contract.inputs.map((input) => ({
      ...input,
      transformations: transformationsWithBindings(input.transformations, bindings),
    })),
    outputs: contract.outputs.map((output) => ({
      ...output,
      transformations: transformationsWithBindings(output.transformations, bindings),
    })),
  };
}

function transformationsWithBindings(
  transformations: ModelContract["inputs"][number]["transformations"],
  bindings: Readonly<Record<string, unknown>>,
) {
  return transformations.map((transformation) => ({
    ...transformation,
    parameters: Object.fromEntries(Object.entries(transformation.parameters).map(
      ([name, parameter]) => [name, resolveParameter(parameter, bindings)],
    )),
  }));
}

function resolveParameter(
  parameter: TransformationParameter,
  bindings: Readonly<Record<string, unknown>>,
): TransformationParameter {
  if (typeof parameter === "string") return resolvedString(parameter, bindings);
  if (typeof parameter === "number" || typeof parameter === "boolean") return parameter;
  if (Array.isArray(parameter)) return parameter.map((item) => resolveParameter(item, bindings));
  return Object.fromEntries(Object.entries(parameter).map(
    ([key, value]) => [key, resolveParameter(value, bindings)],
  )) as TransformationParameterRecord;
}

function resolvedString(
  parameter: string,
  bindings: Readonly<Record<string, unknown>>,
): TransformationParameter {
  const match = parameter.match(bindingPattern);
  if (match === null) return parameter;
  const value = valueAtPath(bindings, match[1].split("."));
  if (!isParameter(value)) {
    throw new Error(`Die Transformationsbindung ${parameter} konnte nicht aufgelöst werden.`);
  }
  return value;
}

function valueAtPath(value: unknown, path: readonly string[]): unknown {
  return path.reduce<unknown>((current, segment) => {
    if (current === null || current === undefined) return undefined;
    if (Array.isArray(current)) return current[Number(segment)];
    if (typeof current !== "object") return undefined;
    return (current as Record<string, unknown>)[segment];
  }, value);
}

function isParameter(value: unknown): value is TransformationParameter {
  if (typeof value === "string" || typeof value === "boolean") return true;
  if (typeof value === "number") return Number.isFinite(value);
  if (Array.isArray(value)) return value.every(isParameter);
  return value !== null && typeof value === "object" && Object.values(value).every(isParameter);
}
