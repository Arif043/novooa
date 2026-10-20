/** Liest `--name wert` aus den Aufrufargumenten; leer oder länger als 200 Zeichen ist ungültig. */
export function optionalArgument(name: string): string | undefined {
  const index = process.argv.indexOf(`--${name}`);
  const value = index === -1 ? undefined : process.argv[index + 1]?.trim();
  if (value === undefined) return undefined;
  if (value.length === 0 || value.length > 200) throw new Error(`--${name} ist ungültig.`);
  return value;
}

export function requiredArgument(name: string): string {
  const value = optionalArgument(name);
  if (value) return value;
  throw new Error(`--${name} fehlt.`);
}

export function hasFlag(name: string): boolean {
  return process.argv.includes(`--${name}`);
}

/** `--max-users 5` oder `--max-users unbegrenzt` (wird `null`). */
export function requiredMaxUsers(): number | null {
  const value = requiredArgument("max-users");
  if (value === "unbegrenzt") return null;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1) throw new Error("--max-users ist ungültig (Zahl ab 1 oder „unbegrenzt“).");
  return parsed;
}

export function reportFailure(error: unknown): void {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
