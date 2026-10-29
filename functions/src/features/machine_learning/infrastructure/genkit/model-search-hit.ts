import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelTagVocabulary} from "../../domain/entities/model-tag-vocabulary.js";

/** Kompakte, artefaktfreie Sicht auf einen Katalogeintrag für Sprachmodelle. */
export type ModelSearchHit = {
  modelId: string;
  title: string;
  description: string;
  task: string;
  /** Fachthemen auf Deutsch; unbekannte Schlüssel (Altbestand) bleiben wie gespeichert. */
  topics: string[];
  languages: string[];
  inputs: string[];
  outputs: string[];
  origin: "global" | "team";
};

export function modelSearchHitFrom(entry: ModelCatalogEntry, vocabulary: ModelTagVocabulary): ModelSearchHit {
  const german = entry.translations?.de;
  return {
    modelId: entry.id,
    title: german?.title ?? entry.title,
    description: german?.description ?? entry.description,
    task: entry.task,
    topics: entry.tags.map((key) => vocabulary.labelFor(key, "de") ?? key),
    languages: [...entry.languages],
    inputs: entry.contract.inputs.map((input) => `${input.name} (${input.source})`),
    outputs: entry.contract.outputs.map((output) => `${output.workflowOutput.name} (${output.workflowOutput.type})`),
    origin: entry.scope.type === "system" ? "global" : "team",
  };
}
