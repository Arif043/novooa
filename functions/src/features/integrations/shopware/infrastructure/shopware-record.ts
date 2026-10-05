/** Lesehilfen für rohe Shopware-Objekte: fehlende oder falsch getypte Teile ergeben leere Werte statt Fehler. */
export type Raw = Record<string, unknown>;

export function isRecord(value: unknown): value is Raw {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function record(value: unknown): Raw {
  return isRecord(value) ? value : {};
}

export function list(value: unknown): Raw[] {
  return Array.isArray(value) ? value.filter(isRecord) : [];
}

export function first(value: unknown): Raw {
  return list(value)[0] ?? {};
}

export function text(value: unknown): string {
  return typeof value === "string" ? value : typeof value === "number" ? String(value) : "";
}

export function number(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

/** Der Anzeigename in der Sprache des Shops (`translated.name`), sonst `name`. */
export function label(value: unknown): string {
  const raw = record(value);
  return text(record(raw.translated).name) || text(raw.name);
}
