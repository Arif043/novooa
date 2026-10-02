import {parse, stringify} from "yaml";

export type SkillManifest = {
  name?: string;
  description?: string;
  license?: string;
  compatibility?: string;
  metadata?: Record<string, string>;
  /** Experimentell im Standard; wir lesen es, werten es aber nicht aus. */
  allowedTools?: string;
  body: string;
};

const frontmatterPattern = /^﻿?---[ \t]*\r?\n([\s\S]*?)\r?\n---[ \t]*(?:\r?\n|$)/;

/** Liest das YAML-Frontmatter einer `SKILL.md`. Ungültiges oder fehlendes Frontmatter ergibt ein Manifest ohne Felder. */
export function parseSkillManifest(markdown: string): SkillManifest {
  const match = frontmatterPattern.exec(markdown);
  if (match === null) return {body: markdown};
  const body = markdown.slice(match[0].length);
  const fields = yamlRecord(match[1]);
  return {
    ...optionalText("name", fields.name),
    ...optionalText("description", fields.description),
    ...optionalText("license", fields.license),
    ...optionalText("compatibility", fields.compatibility),
    ...optionalText("allowedTools", fields["allowed-tools"]),
    ...optionalMetadata(fields.metadata),
    body,
  };
}

function yamlRecord(text: string): Record<string, unknown> {
  try {
    const value: unknown = parse(text);
    return value !== null && typeof value === "object" && !Array.isArray(value) ? value as Record<string, unknown> : {};
  } catch {
    return {};
  }
}

function optionalText<Key extends string>(key: Key, value: unknown): {[K in Key]?: string} {
  if (typeof value !== "string") return {};
  const text = value.replace(/\s+/g, " ").trim();
  return text.length > 0 ? {[key]: text} as {[K in Key]?: string} : {};
}

function optionalMetadata(value: unknown): {metadata?: Record<string, string>} {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return {};
  const entries = Object.entries(value as Record<string, unknown>)
    .filter(([, item]) => item !== null && typeof item !== "object")
    .map(([key, item]) => [key, String(item)] as const);
  return entries.length > 0 ? {metadata: Object.fromEntries(entries)} : {};
}

/**
 * Die `SKILL.md` für die Genkit-Skill-Middleware: Sie liest `name`/`description` mit einer Einzeilen-Suche und
 * kommt mit gefalteter Beschreibung (`description: >`) nicht zurecht. Deshalb schreibt dies den Kopf neu, mit dem
 * Ordnernamen als `name` und einzeiliger Beschreibung; alle übrigen Felder und der Text bleiben erhalten.
 */
export function canonicalSkillMarkdown(markdown: string, name: string): string {
  const match = frontmatterPattern.exec(markdown);
  const fields = match === null ? {} : yamlRecord(match[1]);
  const description = optionalText("description", fields.description).description;
  const header = stringify({...fields, name, ...(description === undefined ? {} : {description})}, {lineWidth: 0});
  const body = match === null ? markdown : markdown.slice(match[0].length);
  return `---\n${header}---\n${body}`;
}
