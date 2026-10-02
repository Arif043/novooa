import {type CatalogAudit, type CatalogBrowseView, type CatalogPage, type CatalogSkill} from "../entities/skill-catalog.js";

/** Ein Skill-Katalog (skills.sh) zum Suchen und Durchstöbern. */
export interface SkillCatalog {
  search(query: string, limit?: number): Promise<CatalogSkill[]>;
  browse(view: CatalogBrowseView, page: number): Promise<CatalogPage>;
  audits(id: string): Promise<CatalogAudit[]>;
}
