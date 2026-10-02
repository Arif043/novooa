import {safeSkillPath, skillEntryFile, SkillPackageError, skillPackageFrom, type SkillFile, type SkillPackage} from "./skill-package.js";

export type DiscoveredSkills = {
  packages: SkillPackage[];
  /** Ordner mit `SKILL.md`, die als Skill unbrauchbar waren (z. B. ohne Beschreibung), samt Grund. */
  rejected: Array<{directory: string; reason: string}>;
};

/**
 * Findet in einer Dateiliste (Pfade relativ zur Wurzel eines Repositorys oder Archivs) alle Skill-Ordner.
 * Ein Skill ist ein Ordner mit `SKILL.md`; seine Dateien sind alle darunter, außer denen eines tiefer
 * verschachtelten Skills. `subPath` begrenzt die Suche auf einen Unterordner. `rootName` benennt einen Skill,
 * dessen `SKILL.md` direkt an der Wurzel liegt.
 */
export function discoverSkills(files: readonly SkillFile[], rootName: string, subPath = ""): DiscoveredSkills {
  const scope = scopeOf(subPath);
  const entries = files.flatMap((file) => {
    const path = safeSkillPath(file.path);
    return path !== null && inScope(path, scope) ? [{path, bytes: file.bytes}] : [];
  });
  const directories = entries
    .filter((file) => file.path === skillEntryFile || file.path.endsWith(`/${skillEntryFile}`))
    .map((file) => file.path.slice(0, file.path.length - skillEntryFile.length).replace(/\/$/, ""));
  const result: DiscoveredSkills = {packages: [], rejected: []};
  for (const directory of [...new Set(directories)].sort()) {
    const own = entries
      .filter((file) => belongsTo(file.path, directory, directories))
      .map((file) => ({path: relative(file.path, directory), bytes: file.bytes}));
    try {
      result.packages.push(skillPackageFrom(own, directory === "" ? rootName : basename(directory)));
    } catch (error) {
      if (!(error instanceof SkillPackageError)) throw error;
      result.rejected.push({directory: directory === "" ? rootName : directory, reason: error.message});
    }
  }
  return result;
}

function scopeOf(subPath: string): string {
  return safeSkillPath(subPath) ?? "";
}

function inScope(path: string, scope: string): boolean {
  return scope === "" || path === scope || path.startsWith(`${scope}/`);
}

function belongsTo(path: string, directory: string, skillDirectories: readonly string[]): boolean {
  if (!isInside(path, directory)) return false;
  return !skillDirectories.some((other) => other !== directory && isInside(other, directory) && isInside(path, other));
}

function isInside(path: string, directory: string): boolean {
  return directory === "" || path === directory || path.startsWith(`${directory}/`);
}

function relative(path: string, directory: string): string {
  return directory === "" ? path : path.slice(directory.length + 1);
}

function basename(directory: string): string {
  return directory.slice(directory.lastIndexOf("/") + 1);
}
