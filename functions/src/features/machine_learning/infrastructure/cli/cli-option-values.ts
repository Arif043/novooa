export type CliOptionRules = {
  /** Optionen ohne Wert, z. B. `--dry-run`. */
  flags: ReadonlySet<string>;
  /** Optionen, die mehrfach vorkommen dürfen. */
  repeatable: ReadonlySet<string>;
};

/** `--name wert` und Schalter → Name ohne `--` zu allen Werten in Reihenfolge. */
export function cliOptionValues(arguments_: readonly string[], rules: CliOptionRules): Map<string, string[]> {
  const values = new Map<string, string[]>();
  for (let index = 0; index < arguments_.length; index += 1) {
    const option = arguments_[index];
    const flag = option?.replace(/^--/, "");
    if (flag !== undefined && flag !== option && rules.flags.has(flag)) values.set(flag, ["true"]);
    else index = addValue(arguments_, index, values, rules);
  }
  return values;
}

export function requiredCliValue(values: ReadonlyMap<string, string[]>, name: string): string {
  const value = values.get(name)?.[0];
  if (value === undefined || value.trim().length === 0) throw new Error(`Die Option --${name} fehlt.`);
  return value;
}

function addValue(arguments_: readonly string[], index: number, values: Map<string, string[]>, rules: CliOptionRules): number {
  const option = arguments_[index];
  if (option === undefined || !option.startsWith("--")) throw new Error(`Unbekannte Option: ${option}`);
  const value = arguments_[index + 1];
  if (value === undefined || value.startsWith("--")) throw new Error(`Der Wert für ${option} fehlt.`);
  const name = option.slice(2);
  if (values.has(name) && !rules.repeatable.has(name)) throw new Error(`Die Option ${option} ist doppelt.`);
  values.set(name, [...values.get(name) ?? [], value]);
  return index + 1;
}
