import {fallbackTagLocale, type ModelTag, validateModelTag} from "./model-tag.js";

/** Ein Eintrag verweist auf Tags, die das Vokabular nicht kennt. */
export class UnknownModelTagError extends Error {
  constructor(readonly keys: readonly string[], vocabularyIsEmpty: boolean) {
    super(
      `Unbekannte Modell-Tags: ${keys.join(", ")}.`
      + (vocabularyIsEmpty ? " Das Tag-Vokabular ist noch nicht geladen." : ""),
    );
    this.name = "UnknownModelTagError";
  }
}

/**
 * Das kontrollierte Tag-Vokabular: eine Ebene Fachthemen mit optionalen Untertags. Es entscheidet,
 * welche Schlüssel gültig sind und welche Suchbegriffe zu welchem Tag passen.
 */
export class ModelTagVocabulary {
  private readonly byKey: ReadonlyMap<string, ModelTag>;

  constructor(readonly tags: readonly ModelTag[]) {
    this.byKey = uniqueTags(tags);
    for (const tag of tags) this.validateParent(tag);
  }

  static empty(): ModelTagVocabulary {
    return new ModelTagVocabulary([]);
  }

  get isEmpty(): boolean {
    return this.tags.length === 0;
  }

  has(key: string): boolean {
    return this.byKey.has(key);
  }

  requireKnown(keys: readonly string[]): void {
    const unknown = keys.filter((key) => !this.byKey.has(key));
    if (unknown.length > 0) throw new UnknownModelTagError(unknown, this.isEmpty);
  }

  /** Die Tags samt Obertags; unbekannte Schlüssel (Altbestand) bleiben unverändert erhalten. */
  withAncestors(keys: readonly string[]): readonly string[] {
    const parents = keys.map((key) => this.byKey.get(key)?.parent).filter((parent) => parent !== undefined);
    return [...new Set([...keys, ...parents])];
  }

  /** Schlüssel, deren Bezeichnung oder Synonym in irgendeiner Sprache den Begriff enthält. */
  keysMatching(term: string): ReadonlySet<string> {
    const wanted = term.toLowerCase();
    return new Set(this.tags.filter((tag) => searchTextsOf(tag).some((text) => text.includes(wanted))).map((tag) => tag.key));
  }

  /** Bezeichnung in der Sprache: exakter Code, dann reine Sprache, sonst Englisch. */
  labelFor(key: string, locale: string): string | undefined {
    const labels = this.byKey.get(key)?.labels;
    if (labels === undefined) return undefined;
    return labels[locale] ?? labels[locale.split("-")[0] ?? ""] ?? labels[fallbackTagLocale];
  }

  private validateParent(tag: ModelTag): void {
    if (tag.parent === undefined) return;
    const parent = this.byKey.get(tag.parent);
    if (parent === undefined) throw new Error(`Der Obertag „${tag.parent}“ von „${tag.key}“ fehlt im Vokabular.`);
    if (parent.parent !== undefined) {
      throw new Error(`Der Obertag „${tag.parent}“ von „${tag.key}“ hat selbst einen Obertag; erlaubt sind zwei Ebenen.`);
    }
  }
}

function uniqueTags(tags: readonly ModelTag[]): ReadonlyMap<string, ModelTag> {
  const byKey = new Map<string, ModelTag>();
  for (const tag of tags) {
    validateModelTag(tag);
    if (byKey.has(tag.key)) throw new Error(`Der Tag „${tag.key}“ steht doppelt im Vokabular.`);
    byKey.set(tag.key, tag);
  }
  return byKey;
}

function searchTextsOf(tag: ModelTag): readonly string[] {
  return [tag.key, ...Object.values(tag.labels), ...Object.values(tag.synonyms ?? {}).flat()]
    .map((text) => text.toLowerCase());
}
