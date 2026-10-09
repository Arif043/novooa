export type ModelSetting = {
  name: string;
  label: string;
  control: ModelSettingControl;
};

export type ModelSettingControl =
  | {type: "slider"; initial: number; minimum: number; maximum: number; step: number}
  | {type: "checkbox"; initial: boolean}
  | {type: "radioGroup"; initial: ModelSettingValue; options: readonly ModelSettingOption[]};

export type ModelSettingValue = string | number | boolean;

export type ModelSettingOption = {
  value: ModelSettingValue;
  label: string;
};

/**
 * Name des Settings, das einen früheren Ausgangsparameter (`outputParameters`) ersetzt.
 * Deterministisch, damit Manifest und gespeicherte Bausteinwerte denselben Namen finden.
 */
export function legacyOutputParameterSettingName(outputName: string, parameterName: string): string {
  const name = `${outputName}_${parameterName}`.replace(/\W/g, "_");
  return /^\d/.test(name) ? `_${name}` : name;
}

export function validateModelSettings(settings: readonly ModelSetting[]): void {
  const names = new Set<string>();
  for (const setting of settings) {
    required(setting.name, "Die Modelleinstellung benötigt einen Namen.");
    required(setting.label, "Die Modelleinstellung benötigt eine Bezeichnung.");
    if (names.has(setting.name)) throw new Error("Modelleinstellungen müssen eindeutige Namen haben.");
    names.add(setting.name);
    validateControl(setting.control);
  }
}

function validateControl(control: ModelSettingControl): void {
  if (control.type === "checkbox") return;
  if (control.type === "slider") return validateSlider(control);
  if (control.options.length === 0 || !control.options.some((option) => option.value === control.initial)) {
    throw new Error("Die Radio-Auswahl benötigt einen gültigen Anfangswert.");
  }
  for (const option of control.options) required(option.label, "Eine Radio-Option benötigt eine Bezeichnung.");
}

function validateSlider(control: Extract<ModelSettingControl, {type: "slider"}>): void {
  const valid = Number.isFinite(control.minimum) && Number.isFinite(control.maximum)
    && Number.isFinite(control.initial) && Number.isFinite(control.step)
    && control.step > 0 && control.minimum < control.maximum
    && control.initial >= control.minimum && control.initial <= control.maximum;
  if (!valid) throw new Error("Der Slider-Modellparameter ist ungültig.");
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
