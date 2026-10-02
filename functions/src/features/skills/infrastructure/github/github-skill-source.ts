import {discoverSkills, type DiscoveredSkills} from "../../domain/entities/skill-discovery.js";
import {SkillImportError} from "../../domain/entities/skill-import-error.js";
import {type SkillSource} from "../../domain/repositories/skill-source.js";
import {readZipFiles, withoutCommonRoot} from "../archive/zip-reader.js";
import {parseGitHubReference, refCandidates} from "./github-reference.js";

export type GitHubSkillReference = {url: string};

const maximumDownloadBytes = 25 * 1024 * 1024;
const downloadTimeoutMilliseconds = 60_000;

/**
 * Lädt ein Repository als ZIP von `codeload.github.com` — das zählt nicht gegen das REST-Limit der
 * GitHub-API (60 Anfragen/Stunde ohne Anmeldung). Öffentliche Repositories genügen.
 */
export class GitHubSkillSource implements SkillSource<GitHubSkillReference> {
  constructor(private readonly request: typeof fetch = fetch) {}

  async resolve({url}: GitHubSkillReference): Promise<DiscoveredSkills> {
    const reference = parseGitHubReference(url);
    for (const {ref, subPath} of refCandidates(reference)) {
      const archive = await this.download(reference.owner, reference.repository, ref);
      if (archive === null) continue;
      const {files} = withoutCommonRoot(readZipFiles(archive));
      const discovered = discoverSkills(files, reference.repository, subPath);
      if (discovered.packages.length === 0 && discovered.rejected.length === 0) {
        throw new SkillImportError(`Im Repository ${reference.owner}/${reference.repository} wurde kein Skill gefunden (ein Skill-Ordner enthält eine Datei SKILL.md).`);
      }
      return discovered;
    }
    throw new SkillImportError(`Das Repository ${reference.owner}/${reference.repository} (oder der angegebene Branch) wurde nicht gefunden. Private Repositories werden nicht unterstützt.`);
  }

  /** `null`, wenn es den Branch nicht gibt (404); andere Fehler brechen ab. */
  private async download(owner: string, repository: string, ref: string): Promise<Uint8Array | null> {
    let response: Response;
    try {
      response = await this.request(`https://codeload.github.com/${owner}/${repository}/zip/${encodeURIComponent(ref).replace(/%2F/g, "/")}`, {
        signal: AbortSignal.timeout(downloadTimeoutMilliseconds),
      });
    } catch {
      throw new SkillImportError("GitHub ist nicht erreichbar. Bitte später erneut versuchen.");
    }
    if (response.status === 404) return null;
    if (response.status === 403 || response.status === 429) {
      throw new SkillImportError("GitHub begrenzt gerade die Anfragen. Bitte in einigen Minuten erneut versuchen.");
    }
    if (!response.ok) throw new SkillImportError(`GitHub hat den Download abgelehnt (${response.status}).`);
    return readLimited(response);
  }
}

async function readLimited(response: Response): Promise<Uint8Array> {
  const declared = Number(response.headers.get("content-length"));
  if (Number.isFinite(declared) && declared > maximumDownloadBytes) throw tooLarge();
  const chunks: Uint8Array[] = [];
  let size = 0;
  const reader = response.body?.getReader();
  if (reader === undefined) throw new SkillImportError("GitHub hat keine Daten geliefert.");
  for (let result = await reader.read(); !result.done; result = await reader.read()) {
    size += result.value.length;
    if (size > maximumDownloadBytes) {
      await reader.cancel();
      throw tooLarge();
    }
    chunks.push(result.value);
  }
  return Buffer.concat(chunks);
}

function tooLarge(): SkillImportError {
  return new SkillImportError(`Das Repository ist zu groß (höchstens ${maximumDownloadBytes / (1024 * 1024)} MB). Verweise auf einen Unterordner oder lade das ZIP des Skills hoch.`);
}
