import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelTagVocabulary} from "../../domain/entities/model-tag-vocabulary.js";

/** Kompakte, artefaktfreie Sicht auf einen Katalogeintrag für Sprachmodelle. */
export type ModelSearchHit = {
  modelId: string;
  titel: string;
  beschreibung: string;
  aufgabe: string;
  /** Fachthemen auf Deutsch; unbekannte Schlüssel (Altbestand) bleiben wie gespeichert. */
  themen: string[];
  sprachen: string[];
  eingaben: string[];
  ausgaben: string[];
  herkunft: "global" | "team";
};

export function modelSearchHitFrom(entry: ModelCatalogEntry, vocabulary: ModelTagVocabulary): ModelSearchHit {
  const german = entry.translations?.de;
  return {
    modelId: entry.id,
    titel: german?.title ?? entry.title,
    beschreibung: german?.description ?? entry.description,
    aufgabe: entry.task,
    themen: entry.tags.map((key) => vocabulary.labelFor(key, "de") ?? key),
    sprachen: [...entry.languages],
    eingaben: entry.contract.inputs.map((input) => `${input.name} (${input.source})`),
    ausgaben: entry.contract.outputs.map((output) => `${output.workflowOutput.name} (${output.workflowOutput.type})`),
    herkunft: entry.scope.type === "system" ? "global" : "team",
  };
}
