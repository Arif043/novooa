const specPattern = /^([A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?)\s*(?:\[([^\]]*)\])?\s*(.*)$/;

/**
 * Die Paketliste eines Script-Bausteins in fester Form: Namen nach PEP 503
 * (klein, `-`/`_`/`.` → `-`), Extras sortiert, Versionsangaben ohne Leerzeichen,
 * ohne Doppelte, sortiert. Gleiche Listen ergeben so dieselbe Umgebung — die
 * Regel gilt gleich im Builder (`PythonPackage.normalized`).
 */
export function normalizedScriptPackages(packages: readonly string[]): string[] {
  const normalized = packages.map(normalizedPackage).filter((spec) => spec.length > 0);
  return [...new Set(normalized)].sort();
}

function normalizedPackage(spec: string): string {
  const match = spec.trim().match(specPattern);
  if (match === null) return spec.trim();
  const [, name, extras, version] = match;
  return `${normalizedName(name)}${extrasOf(extras)}${version.replace(/\s+/g, "")}`;
}

function normalizedName(name: string): string {
  return name.toLowerCase().replace(/[-_.]+/g, "-");
}

function extrasOf(extras: string | undefined): string {
  const names = (extras ?? "").split(",").map((extra) => normalizedName(extra.trim())).filter(Boolean);
  return names.length === 0 ? "" : `[${[...new Set(names)].sort().join(",")}]`;
}
