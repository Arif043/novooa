import {
  type ModelArtifactReference,
  validateModelArtifactReference,
} from "./model-artifact-reference.js";
import {type ModelContract, validateModelContract} from "./model-contract.js";

export type ModelScope =
  | {type: "system"}
  | {type: "team"; teamId: string};

/** Sprachcode (BCP 47, z. B. `en` oder `pt-BR`) → übersetzte Anzeigetexte. */
export type ModelTranslations = Readonly<Record<string, ModelTranslation>>;

export type ModelTranslation = {title: string; description: string};

export type ModelCatalogEntry = {
  id: string;
  title: string;
  description: string;
  /** Optional; `title` und `description` bleiben die Rückfallsprache (Englisch). */
  translations?: ModelTranslations;
  tags: readonly string[];
  scope: ModelScope;
  runtime: "onnx";
  artifactReference: ModelArtifactReference;
  contract: ModelContract;
};

export function validateModelCatalogEntry(entry: ModelCatalogEntry): void {
  required(entry.id, "Die Modell-ID fehlt.");
  required(entry.title, "Der Modellname fehlt.");
  required(entry.description, "Die Modellbeschreibung fehlt.");
  validTags(entry.tags);
  validTranslations(entry.translations ?? {});
  validScope(entry.scope);
  validateModelArtifactReference(entry.artifactReference);
  validateModelContract(entry.contract);
}

function validTags(tags: readonly string[]): void {
  const normalized = tags.map((tag) => tag.trim().toLowerCase());
  if (normalized.some((tag) => tag.length === 0)) throw new Error("Modell-Tags dürfen nicht leer sein.");
  if (new Set(normalized).size !== normalized.length) throw new Error("Modell-Tags müssen eindeutig sein.");
}

function validTranslations(translations: ModelTranslations): void {
  for (const [locale, translation] of Object.entries(translations)) {
    if (!localePattern.test(locale)) throw new Error(`Der Sprachcode „${locale}“ der Modellübersetzung ist ungültig.`);
    required(translation.title, `Der übersetzte Modellname (${locale}) fehlt.`);
    required(translation.description, `Die übersetzte Modellbeschreibung (${locale}) fehlt.`);
  }
}

const localePattern = /^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/;

function validScope(scope: ModelScope): void {
  if (scope.type === "system") return;
  required(scope.teamId, "Der Team-Bereich benötigt eine Team-ID.");
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
