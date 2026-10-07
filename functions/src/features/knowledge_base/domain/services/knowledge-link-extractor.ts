export type KnowledgeLinkTarget = {id: string; title: string; path: string};

/** Links sind eine Projektion des Markdown-Inhalts auf den aktuellen Notizbestand. */
export function knowledgeLinksFrom(content: string, notes: readonly KnowledgeLinkTarget[]): string[] {
  const targets = linkTargets(content);
  return notes.filter((note) => aliasesFor(note).some((alias) => targets.has(alias))).map((note) => note.id);
}

function linkTargets(content: string): Set<string> {
  const targets = new Set<string>();
  for (const match of content.matchAll(/\[\[([^\]|]+)(?:\|[^\]]+)?\]\]/g)) {
    targets.add(normalize(match[1].split(/[#^]/)[0]));
  }
  for (const match of content.matchAll(/\]\(([^)]*)\)/g)) targets.add(normalize(decoded(match[1])));
  return targets;
}

function aliasesFor(note: KnowledgeLinkTarget): string[] {
  const withoutExtension = note.path.endsWith(".md") ? note.path.slice(0, -3) : note.path;
  return [note.id, note.title, note.path, withoutExtension].map(normalize).filter((alias) => alias.length > 0);
}

function normalize(value: string): string {
  return value.trim().toLowerCase();
}

function decoded(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}
