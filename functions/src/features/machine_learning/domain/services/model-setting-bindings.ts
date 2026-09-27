import {
  type ModelSetting,
  type ModelSettingValue,
} from "../entities/model-contract.js";

export function modelSettingBindings(
  settings: readonly ModelSetting[],
  values: Readonly<Record<string, unknown>> = {},
): Record<string, ModelSettingValue> {
  return Object.fromEntries(settings.map((setting) => [
    setting.name,
    valueFor(setting, values[setting.name]),
  ]));
}

function valueFor(parameter: ModelSetting, candidate: unknown): ModelSettingValue {
  const value = candidate ?? parameter.control.initial;
  if (parameter.control.type === "slider") return sliderValue(parameter, value);
  if (parameter.control.type === "checkbox") return booleanValue(parameter, value);
  return radioValue(parameter, value);
}

function sliderValue(parameter: ModelSetting, value: unknown): number {
  const number = typeof value === "number" ? value : Number(value);
  const control = parameter.control;
  if (control.type !== "slider" || !Number.isFinite(number) || number < control.minimum || number > control.maximum) {
    throw new Error(`Der Modellparameter ${parameter.label} ist ungültig.`);
  }
  return number;
}

function booleanValue(parameter: ModelSetting, value: unknown): boolean {
  if (parameter.control.type !== "checkbox") throw new Error("Der Modellparameter ist ungültig.");
  if (typeof value === "boolean") return value;
  if (value === "true") return true;
  if (value === "false") return false;
  throw new Error(`Der Modellparameter ${parameter.label} ist ungültig.`);
}

function radioValue(parameter: ModelSetting, value: unknown): ModelSettingValue {
  if (parameter.control.type !== "radioGroup") throw new Error("Der Modellparameter ist ungültig.");
  const option = parameter.control.options.find((candidate) => matchesOption(candidate.value, value));
  if (option !== undefined) return option.value;
  throw new Error(`Der Modellparameter ${parameter.label} ist ungültig.`);
}

function matchesOption(optionValue: ModelSettingValue, value: unknown): boolean {
  return optionValue === value || (typeof value === "string" && String(optionValue) === value);
}
