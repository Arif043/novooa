import {
  type ModelContract,
  type ModelInput,
  type ModelInputBinding,
  type ModelSetting,
  type ModelSettingControl,
  type ModelSettingOption,
  type ModelInputSourceType,
  type ModelOutput,
  type ModelTensorDataType,
  type TensorDimension,
  type Transformation,
  type TransformationParameter,
  modelTensorDataTypes,
  modelInputSourceTypes,
  validateModelContract,
} from "../domain/entities/model-contract.js";

export function modelContractFromUnknown(value: unknown): ModelContract {
  const data = recordFrom(value, "Der Modellvertrag ist ungültig.");
  const contract = {
    inputs: listFrom(data.inputs, inputFrom),
    outputs: listFrom(data.outputs, outputFrom),
    settings: data.settings === undefined
      ? []
      : listFrom(data.settings, settingFrom),
  };
  validateModelContract(contract);
  return contract;
}

function inputFrom(value: unknown): ModelInput {
  const data = recordFrom(value, "Der Modelleingang ist ungültig.");
  return {
    ...tensorFrom(data),
    source: inputSourceFrom(data.source),
    binding: inputBindingFrom(data.binding),
    transformations: listFrom(data.transformations, transformationFrom),
  };
}

function inputBindingFrom(value: unknown): ModelInputBinding {
  if (value === undefined) return {type: "workflow"};
  const data = recordFrom(value, "Die Modelleingabebindung ist ungültig.");
  if (data.type === "workflow") return {type: "workflow"};
  if (data.type === "derived") return {
    type: "derived",
    inputName: stringFrom(data.inputName, "Die abgeleitete Modelleingabe benötigt einen Namen."),
  };
  if (data.type === "generated") return {type: "generated", value: parameterFrom(data.value)};
  throw new Error("Die Modelleingabebindung ist ungültig.");
}

function settingFrom(value: unknown): ModelSetting {
  const data = recordFrom(value, "Der Modellparameter ist ungültig.");
  return {
    name: stringFrom(data.name, "Der Modellparameter benötigt einen Namen."),
    label: stringFrom(data.label, "Der Modellparameter benötigt eine Bezeichnung."),
    control: settingControlFrom(data.control),
  };
}

function settingControlFrom(value: unknown): ModelSettingControl {
  const data = recordFrom(value, "Das Steuerelement des Modellparameters ist ungültig.");
  if (data.type === "slider") return {
    type: "slider",
    initial: numberFrom(data.initial),
    minimum: numberFrom(data.minimum),
    maximum: numberFrom(data.maximum),
    step: numberFrom(data.step),
  };
  if (data.type === "checkbox") return {type: "checkbox", initial: booleanFrom(data.initial)};
  if (data.type === "radioGroup") return {
    type: "radioGroup",
    initial: settingValueFrom(data.initial),
    options: listFrom(data.options, settingOptionFrom),
  };
  throw new Error("Das Steuerelement des Modellparameters ist ungültig.");
}

function settingOptionFrom(value: unknown): ModelSettingOption {
  const data = recordFrom(value, "Die Radio-Option des Modellparameters ist ungültig.");
  return {
    value: settingValueFrom(data.value),
    label: stringFrom(data.label, "Die Radio-Option benötigt eine Bezeichnung."),
  };
}

function settingValueFrom(value: unknown): string | number | boolean {
  if (typeof value === "string" || typeof value === "boolean") return value;
  return numberFrom(value);
}

function outputFrom(value: unknown): ModelOutput {
  const data = recordFrom(value, "Der Modellausgang ist ungültig.");
  return {
    ...tensorFrom(data),
    semantic: stringFrom(data.semantic, "Die Ausgangssemantik fehlt."),
    transformations: listFrom(data.transformations, transformationFrom),
    workflowOutput: workflowOutputFrom(data),
  };
}

function workflowOutputFrom(data: Record<string, unknown>): ModelOutput["workflowOutput"] {
  const output = recordFrom(data.workflowOutput, "Die Workflow-Ausgabe fehlt.");
  return {
    name: stringFrom(output.name, "Der Name der Workflow-Ausgabe fehlt."),
    type: workflowTypeFrom(output.type),
    mapping: parameterFrom(output.mapping),
  };
}

function workflowTypeFrom(value: unknown): ModelOutput["workflowOutput"]["type"] {
  if (value === "string" || value === "number" || value === "boolean" || value === "json" || value === "audio") {
    return value;
  }
  throw new Error("Der Typ der Workflow-Ausgabe ist ungültig.");
}

function tensorFrom(data: Record<string, unknown>) {
  return {
    name: stringFrom(data.name, "Der Tensor-Name fehlt."),
    dataType: dataTypeFrom(data.dataType),
    shape: listFrom(data.shape, dimensionFrom),
  };
}

function transformationFrom(value: unknown): Transformation {
  const data = recordFrom(value, "Die Transformation ist ungültig.");
  return {
    type: stringFrom(data.type, "Der Transformationstyp fehlt."),
    parameters: parametersFrom(data.parameters),
    ...(data.result === undefined ? {} : {result: stringFrom(data.result, "Der Name des Transformations-Ergebnisses fehlt.")}),
  };
}

function parametersFrom(
  value: unknown,
): Readonly<Record<string, TransformationParameter>> {
  const parameters = recordFrom(
    value,
    "Die Transformationsparameter sind ungültig.",
  );
  return Object.fromEntries(
    Object.entries(parameters).map(([key, item]) => [key, parameterFrom(item)]),
  );
}

function parameterFrom(value: unknown): TransformationParameter {
  if (typeof value === "string" || typeof value === "boolean") return value;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (Array.isArray(value)) return value.map(parameterFrom);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, parameterFrom(item)]),
    );
  }
  throw new Error("Ein Transformationsparameter ist ungültig.");
}

function numberFrom(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  throw new Error("Der Modellparameter benötigt eine Zahl.");
}

function booleanFrom(value: unknown): boolean {
  if (typeof value === "boolean") return value;
  throw new Error("Der Modellparameter benötigt einen Wahrheitswert.");
}

function dataTypeFrom(value: unknown): ModelTensorDataType {
  if (
    typeof value === "string" &&
    modelTensorDataTypes.includes(value as ModelTensorDataType)
  ) {
    return value as ModelTensorDataType;
  }
  throw new Error("Der Tensor-Datentyp ist ungültig.");
}

function dimensionFrom(value: unknown): TensorDimension {
  if (value === "dynamic") return value;
  if (typeof value === "number" && Number.isSafeInteger(value) && value > 0)
    return value;
  throw new Error("Eine Tensor-Dimension ist ungültig.");
}

function inputSourceFrom(value: unknown): ModelInputSourceType {
  if (typeof value === "string" && modelInputSourceTypes.includes(value as ModelInputSourceType)) {
    return value as ModelInputSourceType;
  }
  throw new Error("Die Eingabequelle ist ungültig.");
}

function listFrom<T>(
  value: unknown,
  itemFrom: (item: unknown) => T,
): readonly T[] {
  if (!Array.isArray(value))
    throw new Error("Eine Modellvertrag-Liste ist ungültig.");
  return value.map(itemFrom);
}

function recordFrom(value: unknown, message: string): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(message);
  }
  return value as Record<string, unknown>;
}

function stringFrom(value: unknown, message: string): string {
  if (typeof value !== "string" || value.trim().length === 0)
    throw new Error(message);
  return value;
}
