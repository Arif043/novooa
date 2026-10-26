import {cliOptionValues, requiredCliValue} from "./cli-option-values.js";

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

const rules = {
  flags: new Set(["dry-run", "replace-version"]),
  repeatable: new Set(["external-data", "resource"]),
};

export function modelPublishOptionsFromArguments(arguments_: readonly string[]): ModelPublishOptions {
  const values = cliOptionValues(arguments_, rules);
  return {
    projectId: requiredCliValue(values, "project"),
    manifestPath: requiredCliValue(values, "manifest"),
    artifactPath: requiredCliValue(values, "artifact"),
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
  "Die Tags des Manifests müssen im globalen Vokabular stehen (zuerst models:tags:publish).",
  "Der Modellspeicher kommt aus MODEL_STORE_S3_ENDPOINT, _REGION, _BUCKET, _ACCESS_KEY_ID, _SECRET_ACCESS_KEY.",
].join("\n");

function resourceFrom(value: string): {name: string; path: string} {
  const separator = value.indexOf("=");
  if (separator <= 0 || separator === value.length - 1) throw new Error("--resource erwartet <name>=<datei>.");
  return {name: value.slice(0, separator), path: value.slice(separator + 1)};
}
