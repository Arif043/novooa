/**
 * Ein Name, der im Zielordner noch frei ist: `Bericht (Kopie).pdf`, dann
 * `Bericht (Kopie) (2).pdf`. Die Endung bleibt, damit der Dateityp erkennbar bleibt.
 */
export function uniqueFileNameFor(desiredName: string, takenNames: ReadonlySet<string>): string {
  if (!takenNames.has(desiredName)) return desiredName;
  const {base, extension} = splitFileName(desiredName);
  for (let counter = 2; ; counter++) {
    const candidate = `${base} (${counter})${extension}`;
    if (!takenNames.has(candidate)) return candidate;
  }
}

function splitFileName(name: string): {base: string; extension: string} {
  const dot = name.lastIndexOf(".");
  if (dot <= 0) return {base: name, extension: ""};
  return {base: name.slice(0, dot), extension: name.slice(dot)};
}
