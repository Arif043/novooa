import {SkillCatalogError, type CatalogAudit, type CatalogBrowseView, type CatalogPage, type CatalogSkill} from "../../domain/entities/skill-catalog.js";
import {type SkillCatalog} from "../../domain/repositories/skill-catalog.js";
import {type SkillsShClient} from "./skills-sh-client.js";

const searchTtlSeconds = 60;
const detailTtlSeconds = 300;
const minimumQueryLength = 2;
const defaultLimit = 30;
const pageSize = 30;

/** Katalog-Adapter für skills.sh: Suche, Bestenliste und Sicherheits-Audits. */
export class SkillsShCatalog implements SkillCatalog {
  constructor(private readonly client: SkillsShClient) {}

  async search(query: string, limit = defaultLimit): Promise<CatalogSkill[]> {
    const text = query.trim();
    if (text.length < minimumQueryLength) {
      throw new SkillCatalogError(`Die Suche braucht mindestens ${minimumQueryLength} Zeichen.`, "invalid");
    }
    const body = await this.client.get<{data?: unknown}>("/skills/search", {q: text, limit: Math.min(Math.max(limit, 1), 200)}, searchTtlSeconds);
    return skillsFrom(body.data);
  }

  async browse(view: CatalogBrowseView, page: number): Promise<CatalogPage> {
    const body = await this.client.get<{data?: unknown; pagination?: {hasMore?: unknown}}>(
      "/skills", {view, page: Math.max(page, 0), per_page: pageSize}, searchTtlSeconds,
    );
    return {items: skillsFrom(body.data), hasMore: body.pagination?.hasMore === true};
  }

  async audits(id: string): Promise<CatalogAudit[]> {
    try {
      const body = await this.client.get<{audits?: unknown}>(`/skills/audit/${catalogPath(id)}`, {}, detailTtlSeconds);
      return Array.isArray(body.audits) ? body.audits.flatMap(auditFrom) : [];
    } catch (error) {
      // Noch nicht geprüfte Skills liefern 404; das ist „keine Audits“, kein Fehler.
      if (error instanceof SkillCatalogError && error.kind === "not_found") return [];
      throw error;
    }
  }
}

/** `quelle/slug` → URL-Pfad; Kennungen mit `..` oder leeren Teilen werden abgelehnt. */
export function catalogPath(id: string): string {
  const segments = id.split("/");
  if (segments.length < 2 || segments.some((segment) => segment === "" || segment === "." || segment === "..")) {
    throw new SkillCatalogError("Die Skill-Kennung ist ungültig.", "invalid");
  }
  return segments.map(encodeURIComponent).join("/");
}

function skillsFrom(data: unknown): CatalogSkill[] {
  if (!Array.isArray(data)) return [];
  return data.flatMap((item): CatalogSkill[] => {
    const skill = item as Record<string, unknown> | null;
    if (skill === null || typeof skill.id !== "string" || typeof skill.slug !== "string") return [];
    return [{
      id: skill.id, slug: skill.slug, name: typeof skill.name === "string" ? skill.name : skill.slug,
      source: typeof skill.source === "string" ? skill.source : "",
      installs: typeof skill.installs === "number" ? skill.installs : 0,
      sourceType: typeof skill.sourceType === "string" ? skill.sourceType : "",
      url: typeof skill.url === "string" ? skill.url : "",
      isDuplicate: skill.isDuplicate === true,
    }];
  });
}

function auditFrom(item: unknown): CatalogAudit[] {
  const audit = item as Record<string, unknown> | null;
  if (audit === null || typeof audit.provider !== "string") return [];
  const status = audit.status === "pass" || audit.status === "warn" || audit.status === "fail" ? audit.status : "warn";
  return [{
    provider: audit.provider, status, summary: typeof audit.summary === "string" ? audit.summary : "",
    ...(typeof audit.riskLevel === "string" ? {riskLevel: audit.riskLevel} : {}),
    ...(typeof audit.auditedAt === "string" ? {auditedAt: audit.auditedAt} : {}),
  }];
}
