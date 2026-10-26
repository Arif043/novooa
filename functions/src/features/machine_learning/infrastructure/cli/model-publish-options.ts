export type ModelPublishOptions = {
  projectId: string;
  manifestPath: string;
  artifactPath: string;
  externalDataPaths: readonly string[];
  resources: readonly {name: string; path: string}[];
  pythonExecutable: string;
  dryRun: boolean;
  /** Erlaubt, eine schon veröffentlichte andere Version derselben Modell-ID zu ersetzen. */
  replaceVersion: boolean;
};

const repeatable = new Set(["external-data", "resource"]);
const flags = new Set(["dry-run", "replace-version"]);

export function modelPublishOptionsFromArguments(arguments_: readonly string[]): ModelPublishOptions {
  const values = optionValues(arguments_);
  return {
    projectId: requiredValue(values, "project"),
    manifestPath: requiredValue(values, "manifest"),
    artifactPath: requiredValue(values, "artifact"),
    externalDataPaths: values.get("external-data") ?? [],
    resources: (values.get("resource") ?? []).map(resourceFrom),
    pythonExecutable: values.get("python")?.[0] ?? process.env.PYTHON_EXECUTABLE ?? "python3",
    dryRun: values.has("dry-run"),
    replaceVersion: values.has("replace-version"),
  };
}

export const modelPublishUsage = [
  "Verwendung: npm --prefix functions run models:publish -- --project <projekt-id>",
  "  --manifest <model.json> --artifact <model.onnx> [--external-data <datei>]... [--resource <name>=<datei>]...",
  "  [--python <pfad>] [--dry-run] [--replace-version]",
  "Gewichtsdateien liegen im Ordner des Modells; ihr Dateiname ist der Name, unter dem das Modell sie erwartet.",
  "--replace-version ersetzt eine schon veröffentlichte andere Version derselben Modell-ID.",
  "Der Modellspeicher kommt aus MODEL_STORE_S3_ENDPOINT, _REGION, _BUCKET, _ACCESS_KEY_ID, _SECRET_ACCESS_KEY.",
].join("\n");

function optionValues(arguments_: readonly string[]): Map<string, string[]> {
  const values = new Map<string, string[]>();
  for (let index = 0; index < arguments_.length; index += 1) {
    const option = arguments_[index];
    const flag = option?.replace(/^--/, "");
    if (flag !== undefined && flag !== option && flags.has(flag)) values.set(flag, ["true"]);
    else index = addValue(arguments_, index, values);
  }
  return values;
}

function addValue(arguments_: readonly string[], index: number, values: Map<string, string[]>): number {
  const option = arguments_[index];
  if (option === undefined || !option.startsWith("--")) throw new Error(`Unbekannte Option: ${option}`);
  const value = arguments_[index + 1];
  if (value === undefined || value.startsWith("--")) throw new Error(`Der Wert für ${option} fehlt.`);
  const name = option.slice(2);
  if (values.has(name) && !repeatable.has(name)) throw new Error(`Die Option ${option} ist doppelt.`);
  values.set(name, [...values.get(name) ?? [], value]);
  return index + 1;
}

function resourceFrom(value: string): {name: string; path: string} {
  const separator = value.indexOf("=");
  if (separator <= 0 || separator === value.length - 1) throw new Error("--resource erwartet <name>=<datei>.");
  return {name: value.slice(0, separator), path: value.slice(separator + 1)};
}

function requiredValue(values: ReadonlyMap<string, string[]>, name: string): string {
  const value = values.get(name)?.[0];
  if (value === undefined || value.trim().length === 0) throw new Error(`Die Option --${name} fehlt.`);
  return value;
}
