import {SkillNotFoundError, type StoredSkill} from "../entities/stored-skill.js";
import {type SkillStore} from "../repositories/skill-store.js";

export class ListSkills {
  constructor(private readonly store: SkillStore) {}

  execute(): Promise<StoredSkill[]> {
    return this.store.list();
  }
}

export class DeleteSkill {
  constructor(private readonly store: SkillStore) {}

  async execute(name: string): Promise<void> {
    if (!(await this.store.list()).some((skill) => skill.name === name)) throw new SkillNotFoundError(name);
    await this.store.delete(name);
  }
}
