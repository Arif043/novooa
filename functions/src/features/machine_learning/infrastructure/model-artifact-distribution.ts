export type ModelArtifactDistribution = {
  type: "huggingFace";
  repository: string;
  revision: string;
  path: string;
  resources?: readonly {name: string; path: string}[];
};

export function modelArtifactDistributionFromUnknown(
  value: unknown,
): ModelArtifactDistribution {
  const data = record(value);
  if (data.type !== "huggingFace") throw new Error("Die Modell-Distribution ist ungültig.");
  const distribution = {
    type: "huggingFace" as const,
    repository: text(data.repository),
    revision: text(data.revision),
    path: text(data.path),
    resources: resources(data.resources),
  };
  validateDistribution(distribution);
  return distribution;
}

function resources(value: unknown): readonly {name: string; path: string}[] | undefined {
  if (value === undefined) return undefined;
  if (!Array.isArray(value)) throw new Error("Die Modell-Distribution ist ungültig.");
  const names = new Set<string>();
  return value.map((item) => {
    const data = record(item);
    const resource = {name: text(data.name), path: text(data.path)};
    if (names.has(resource.name)) throw new Error("Die Modell-Distribution enthält doppelte Ressourcen.");
    names.add(resource.name);
    if (resource.path.startsWith("/") || resource.path.includes("..")) throw new Error("Der Pfad zu einer Modellressource ist ungültig.");
    return resource;
  });
}

function validateDistribution(distribution: ModelArtifactDistribution): void {
  if (!/^[^/\s]+\/[^/\s]+$/.test(distribution.repository)) throw new Error("Das Hugging-Face-Repository ist ungültig.");
  if (!/^[a-f0-9]{40}$/i.test(distribution.revision)) throw new Error("Die Hugging-Face-Revision muss ein vollständiger Commit-Hash sein.");
  if (distribution.path.startsWith("/") || distribution.path.includes("..")) {
    throw new Error("Der Pfad zum Hugging-Face-Artefakt ist ungültig.");
  }
}

function record(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Die Modell-Distribution ist ungültig.");
  }
  return value as Record<string, unknown>;
}

function text(value: unknown): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new Error("Die Modell-Distribution ist ungültig.");
  return value;
}
