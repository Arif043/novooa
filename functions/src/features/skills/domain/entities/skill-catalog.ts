export type CatalogSkill = {
  /** Stabile Kennung `{quelle}/{slug}`, z. B. `vercel-labs/skills/find-skills`. */
  id: string;
  slug: string;
  name: string;
  source: string;
  installs: number;
  sourceType: string;
  url: string;
  isDuplicate: boolean;
};

export type CatalogBrowseView = "all-time" | "trending" | "hot";

export type CatalogPage = {items: CatalogSkill[]; hasMore: boolean};

export type CatalogAudit = {
  provider: string;
  status: "pass" | "warn" | "fail";
  summary: string;
  riskLevel?: string;
  auditedAt?: string;
};

export type SkillCatalogErrorKind = "rate_limited" | "not_found" | "unauthorized" | "unavailable" | "invalid";

/** Ein Katalogfehler mit einer Meldung, die der Nutzer lesen darf. */
export class SkillCatalogError extends Error {
  constructor(message: string, readonly kind: SkillCatalogErrorKind, readonly retryAfterSeconds?: number) {
    super(message);
    this.name = "SkillCatalogError";
  }
}
