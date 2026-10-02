import {SkillImportError} from "../../domain/entities/skill-import-error.js";

export type GitHubReference = {
  owner: string;
  repository: string;
  /** Segmente hinter `/tree/` oder `/blob/` (Branch, evtl. mit `/`, danach der Pfad); leer = Standard-Branch. */
  rest: string[];
  /** `blob`-Adresse auf eine Datei: der Pfad ist dann die Datei und gesucht wird ihr Ordner. */
  isFile: boolean;
};

const namePattern = /^[A-Za-z0-9_.-]+$/;

/** Versteht `https://github.com/o/r`, `…/tree/<branch>/<pfad>`, `…/blob/<branch>/<pfad>/SKILL.md`, `github.com/o/r` und `o/r`. */
export function parseGitHubReference(text: string): GitHubReference {
  const trimmed = text.trim();
  const path = pathOf(trimmed);
  const [owner, rawRepository, kind, ...rest] = path.split("/").filter((segment) => segment !== "");
  const repository = rawRepository?.replace(/\.git$/, "");
  if (!owner || !repository || !namePattern.test(owner) || !namePattern.test(repository)) {
    throw new SkillImportError("Die GitHub-Adresse ist ungültig. Beispiel: https://github.com/besitzer/repository");
  }
  const isTree = kind === "tree" || kind === "blob";
  return {owner, repository, rest: isTree ? rest : [], isFile: kind === "blob"};
}

function pathOf(text: string): string {
  const withScheme = /^[a-z]+:\/\//i.test(text) ? text : /^(www\.)?github\.com\//i.test(text) ? `https://${text}` : null;
  if (withScheme === null) return text;
  let url: URL;
  try {
    url = new URL(withScheme);
  } catch {
    throw new SkillImportError("Die GitHub-Adresse ist ungültig.");
  }
  if (!/^(www\.)?github\.com$/i.test(url.hostname)) {
    throw new SkillImportError("Es werden nur GitHub-Adressen unterstützt (github.com).");
  }
  return url.pathname;
}

/** Mögliche Aufteilungen von `rest` in Branch und Unterpfad; Branches mit `/` (z. B. `feature/x`) kommen vor. */
export function refCandidates(reference: GitHubReference): Array<{ref: string; subPath: string}> {
  if (reference.rest.length === 0) return [{ref: "HEAD", subPath: ""}];
  const candidates: Array<{ref: string; subPath: string}> = [];
  for (let length = 1; length <= Math.min(reference.rest.length, 3); length++) {
    const subSegments = reference.rest.slice(length);
    if (reference.isFile) subSegments.pop();
    candidates.push({ref: reference.rest.slice(0, length).join("/"), subPath: subSegments.join("/")});
  }
  return candidates;
}
