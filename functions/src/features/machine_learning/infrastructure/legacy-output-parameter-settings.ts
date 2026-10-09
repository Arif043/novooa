import {
  type ModelContract,
  type ModelOutput,
  type ModelSetting,
  type Transformation,
} from "../domain/entities/model-contract.js";
import {legacyOutputParameterSettingName} from "../domain/entities/model-setting.js";

type LegacyDescription = {name: string; label: string; initial: number; minimum: number; maximum: number};

/**
 * Ältere Manifeste machten einen Ausgangsparameter über eine Beschreibung
 * `{"parameter": {name, label, default, minimum, maximum}}` einstellbar. Heute erledigen das
 * Settings: Die Beschreibung wird zu einem Slider-Setting `<ausgang>_<name>`, der Parameter
 * zur Bindung `"$<ausgang>_<name>"`. Der Name ist deterministisch, damit auch gespeicherte
 * Bausteinwerte (`outputParameters`) denselben Namen finden.
 */
export function withLegacyOutputParametersAsSettings(contract: ModelContract): ModelContract {
  const converted: ModelSetting[] = [];
  const outputs = contract.outputs.map((output) => ({
    ...output,
    transformations: output.transformations.map((transformation) => convert(output, transformation, converted)),
  }));
  if (converted.length === 0) return contract;
  return {...contract, outputs, settings: [...(contract.settings ?? []), ...converted]};
}

function convert(output: ModelOutput, transformation: Transformation, converted: ModelSetting[]): Transformation {
  const description = legacyDescription(transformation.parameters.parameter);
  if (description === null) return transformation;
  const name = legacyOutputParameterSettingName(output.name, description.name);
  converted.push({
    name,
    label: description.label,
    control: {type: "slider", initial: description.initial, minimum: description.minimum, maximum: description.maximum, step: 1},
  });
  const {parameter: _legacy, ...parameters} = transformation.parameters;
  return {...transformation, parameters: {...parameters, [description.name]: `$${name}`}};
}

function legacyDescription(value: unknown): LegacyDescription | null {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return null;
  const data = value as Record<string, unknown>;
  const {name, label, minimum, maximum} = data;
  const initial = data.default;
  if (typeof name !== "string" || name.length === 0) return null;
  if (![initial, minimum, maximum].every((item) => typeof item === "number" && Number.isFinite(item))) return null;
  return {
    name, label: typeof label === "string" && label.length > 0 ? label : name,
    initial: initial as number, minimum: minimum as number, maximum: maximum as number,
  };
}
