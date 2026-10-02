import {type SkillPackage} from "../entities/skill-package.js";
import {type StoredSkill} from "../entities/stored-skill.js";
import {type SkillContentReader} from "./skill-content-reader.js";

/** Der Skills-Ordner des Nutzers: jeder Skill ist ein Unterordner mit `SKILL.md`. */
export interface SkillStore extends SkillContentReader {
  list(): Promise<StoredSkill[]>;
  /** Legt den Skill als Ordner an; wirft `SkillAlreadyExistsError`, wenn der Name vergeben ist. */
  save(skill: SkillPackage): Promise<StoredSkill>;
  delete(name: string): Promise<void>;
}
