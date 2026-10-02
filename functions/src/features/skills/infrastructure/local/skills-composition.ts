import path from "node:path";
import {CommitSkillImport} from "../../domain/usecases/commit-skill-import.js";
import {PreviewSkillImport} from "../../domain/usecases/preview-skill-import.js";
import {DeleteSkill, ListSkills} from "../../domain/usecases/skill-library.js";
import {ZipSkillSource} from "../archive/zip-skill-source.js";
import {FolderSkillSource} from "../files/folder-skill-source.js";
import {GitHubSkillSource} from "../github/github-skill-source.js";
import {DirectorySkillStore} from "./directory-skill-store.js";
import {InMemoryStagedSkillImports} from "./in-memory-staged-skill-imports.js";
import {SkillsShCatalog} from "../skills_sh/skills-sh-catalog.js";
import {SkillsShClient, type SkillsShConfig} from "../skills_sh/skills-sh-client.js";
import {SkillsShSkillSource} from "../skills_sh/skills-sh-skill-source.js";
import {type SkillCatalogRoutesOptions} from "./local-skill-catalog-routes.js";
import {type SkillRoutesOptions} from "./local-skill-routes.js";

/** Der Skills-Ordner: `NOVOOA_SKILLS_DIR` oder `<runtimeRoot>/skills`. */
export function skillsDirectoryFor(runtimeRoot: string, environment: NodeJS.ProcessEnv = process.env): string {
  const configured = environment.NOVOOA_SKILLS_DIR?.trim();
  return configured ? path.resolve(configured) : path.join(runtimeRoot, "skills");
}

export function createDirectorySkillStore(runtimeRoot: string): DirectorySkillStore {
  return new DirectorySkillStore(skillsDirectoryFor(runtimeRoot));
}

/**
 * Zugang zu skills.sh: `SKILLS_SH_BASE_URL` (Proxy) mit optionalem `SKILLS_SH_TOKEN`; nur mit Token direkt gegen
 * `https://skills.sh/api/v1`. Ohne beides gibt es keinen Katalog (GitHub/ZIP/Ordner funktionieren trotzdem).
 */
export function skillsShConfigFrom(environment: NodeJS.ProcessEnv = process.env): SkillsShConfig | undefined {
  const baseUrl = environment.SKILLS_SH_BASE_URL?.trim();
  const token = environment.SKILLS_SH_TOKEN?.trim();
  if (baseUrl) return {baseUrl, ...(token ? {token} : {})};
  return token ? {baseUrl: "https://skills.sh/api/v1", token} : undefined;
}

export type SkillsModule = {routes: SkillRoutesOptions; catalog: SkillCatalogRoutesOptions};

/** Baut Skills-Routen und Katalog-Routen um **einen** skills.sh-Client, damit Rate-Limit und Cache gemeinsam gelten. */
export function createSkillsModule(
  runtimeRoot: string, notifier: SkillRoutesOptions["notifier"], config: SkillsShConfig | null = skillsShConfigFrom() ?? null,
): SkillsModule {
  const store = createDirectorySkillStore(runtimeRoot);
  const staged = new InMemoryStagedSkillImports();
  const client = config === null ? undefined : new SkillsShClient(config);
  return {
    routes: {
      store,
      list: new ListSkills(store),
      remove: new DeleteSkill(store),
      preview: new PreviewSkillImport(store, staged),
      commit: new CommitSkillImport(store, staged),
      sources: {
        github: new GitHubSkillSource(), archive: new ZipSkillSource(), folder: new FolderSkillSource(),
        ...(client === undefined ? {} : {skillsSh: new SkillsShSkillSource(client)}),
      },
      notifier,
    },
    catalog: client === undefined ? {} : {catalog: new SkillsShCatalog(client)},
  };
}
