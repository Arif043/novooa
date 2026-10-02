import {type DiscoveredSkills} from "../entities/skill-discovery.js";

/** Eine Quelle, aus der sich Skills importieren lassen (GitHub, ZIP, Ordner, skills.sh). */
export interface SkillSource<Reference> {
  resolve(reference: Reference): Promise<DiscoveredSkills>;
}
