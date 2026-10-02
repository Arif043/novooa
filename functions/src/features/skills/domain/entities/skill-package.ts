import {parseSkillManifest} from "./skill-manifest.js";
import {SkillName} from "./skill-name.js";

export type SkillFile = {
  /** Relativ zum Skill-Ordner, immer mit `/` getrennt. */
  path: string;
  bytes: Uint8Array;
};

export type SkillPackage = {
  name: string;
  description: string;
  license?: string;
  compatibility?: string;
  files: SkillFile[];
  /** Hinweise, die der Import anzeigt (z. B. korrigierter Name), ohne ihn zu verhindern. */
  warnings: string[];
};

export const skillLimits = {
  maximumFiles: 200,
  maximumTotalBytes: 10 * 1024 * 1024,
  maximumDescriptionLength: 1024,
  maximumCompatibilityLength: 500,
} as const;

export const skillEntryFile = "SKILL.md";

/** Ein Fehler mit einer Meldung, die der Nutzer lesen darf. */
export class SkillPackageError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "SkillPackageError";
  }
}

const ignoredSegments = new Set([".git", "__MACOSX", ".DS_Store", "node_modules"]);

/** Gültiger relativer Pfad innerhalb des Skills, sonst `null`: kein `..`, nicht absolut, kein Laufwerk. */
export function safeSkillPath(path: string): string | null {
  const normalized = path.replace(/\\/g, "/");
  if (normalized.startsWith("/") || /^[A-Za-z]:/.test(normalized) || normalized.includes("\0")) return null;
  const segments = normalized.split("/").filter((segment) => segment !== "" && segment !== ".");
  if (segments.length === 0 || segments.includes("..")) return null;
  return segments.join("/");
}

/**
 * Baut aus den Dateien eines Skill-Ordners (`SKILL.md` liegt an der Wurzel) ein Paket. `fallbackName` ist der
 * Ordnername der Quelle und ersetzt einen fehlenden oder ungültigen `name`. Reale Skills halten den Standard nicht
 * immer ein; deshalb wird korrigiert und gewarnt, abgelehnt nur bei fehlender Beschreibung oder verletzten Grenzen.
 */
export function skillPackageFrom(files: readonly SkillFile[], fallbackName: string): SkillPackage {
  const kept = keptFiles(files);
  const entry = kept.find((file) => file.path === skillEntryFile);
  if (entry === undefined) throw new SkillPackageError(`Im Skill „${fallbackName}“ fehlt die Datei ${skillEntryFile}.`);
  enforceLimits(kept, fallbackName);
  const manifest = parseSkillManifest(new TextDecoder().decode(entry.bytes));
  const warnings: string[] = [];
  const description = manifest.description;
  if (description === undefined) {
    throw new SkillPackageError(`Im Skill „${fallbackName}“ fehlt die Beschreibung (description) im Kopf der ${skillEntryFile}.`);
  }
  if (description.length > skillLimits.maximumDescriptionLength) {
    warnings.push(`Die Beschreibung wurde auf ${skillLimits.maximumDescriptionLength} Zeichen gekürzt.`);
  }
  return {
    name: nameFor(manifest.name, fallbackName, warnings).value,
    description: description.slice(0, skillLimits.maximumDescriptionLength),
    ...(manifest.license ? {license: manifest.license} : {}),
    ...(manifest.compatibility ? {compatibility: manifest.compatibility.slice(0, skillLimits.maximumCompatibilityLength)} : {}),
    files: kept,
    warnings,
  };
}

function keptFiles(files: readonly SkillFile[]): SkillFile[] {
  const byPath = new Map<string, SkillFile>();
  for (const file of files) {
    const path = safeSkillPath(file.path);
    if (path === null) throw new SkillPackageError(`Ungültiger Dateipfad im Skill: ${file.path}`);
    if (path.split("/").some((segment) => ignoredSegments.has(segment))) continue;
    byPath.set(path, {path, bytes: file.bytes});
  }
  return [...byPath.values()];
}

function enforceLimits(files: readonly SkillFile[], skillName: string): void {
  if (files.length > skillLimits.maximumFiles) {
    throw new SkillPackageError(`Der Skill „${skillName}“ hat zu viele Dateien (höchstens ${skillLimits.maximumFiles}).`);
  }
  const total = files.reduce((sum, file) => sum + file.bytes.length, 0);
  if (total > skillLimits.maximumTotalBytes) {
    const megabytes = Math.floor(skillLimits.maximumTotalBytes / (1024 * 1024));
    throw new SkillPackageError(`Der Skill „${skillName}“ ist zu groß (höchstens ${megabytes} MB).`);
  }
}

function nameFor(declared: string | undefined, fallbackName: string, warnings: string[]): SkillName {
  const valid = declared === undefined ? null : SkillName.parse(declared);
  if (valid !== null) return valid;
  const slug = SkillName.slugFrom(declared ?? fallbackName) ?? SkillName.slugFrom(fallbackName) ?? SkillName.parse("skill")!;
  warnings.push(declared === undefined
    ? `Der Skill hat keinen Namen; „${slug.value}“ wurde aus dem Ordnernamen abgeleitet.`
    : `Der Name „${declared}“ erfüllt den Standard nicht; verwendet wird „${slug.value}“.`);
  return slug;
}
