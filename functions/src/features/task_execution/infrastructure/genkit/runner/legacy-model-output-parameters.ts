import {legacyOutputParameterSettingName} from "../../../../machine_learning/domain/entities/model-setting.js";

const MODEL_PRIMITIVES = new Set(["modelInference", "textToSpeech", "speechToText"]);

type RawSetting = {name: string; valueTemplate: string};

/**
 * Gespeicherte Modell-Bausteine konnten Ausgangsparameter als `outputParameters` tragen.
 * Heute sind das Settings: Jeder Eintrag wird zum Setting `<ausgang>_<name>` mit dem
 * gespeicherten Wert. Ein vorhandenes Setting gleichen Namens behält Vorrang.
 */
export function withLegacyOutputParametersAsSettings(config: unknown): unknown {
  if (!isRecord(config) || !MODEL_PRIMITIVES.has(String(config.primitive)) || !Array.isArray(config.outputParameters)) {
    return config;
  }
  const {outputParameters, ...rest} = config;
  const settings = Array.isArray(rest.settings) ? [...rest.settings as RawSetting[]] : [];
  const names = new Set(settings.map((setting) => setting?.name));
  for (const parameter of outputParameters as unknown[]) {
    const setting = settingFor(parameter);
    if (setting === null || names.has(setting.name)) continue;
    names.add(setting.name);
    settings.push(setting);
  }
  return {...rest, settings};
}

function settingFor(value: unknown): RawSetting | null {
  if (!isRecord(value) || typeof value.outputName !== "string" || typeof value.name !== "string") return null;
  if (typeof value.value !== "number" || !Number.isFinite(value.value)) return null;
  return {name: legacyOutputParameterSettingName(value.outputName, value.name), valueTemplate: String(value.value)};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
