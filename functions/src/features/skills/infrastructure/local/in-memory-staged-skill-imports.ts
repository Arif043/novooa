import {randomUUID} from "node:crypto";
import {type StagedSkillImport} from "../../domain/entities/skill-import-preview.js";
import {type StagedSkillImports} from "../../domain/repositories/staged-skill-imports.js";

const defaultLifetimeMs = 15 * 60 * 1000;
const maximumStaged = 10;

/** Vorschauen im Speicher: klein (höchstens 10 MB je Skill), kurzlebig und beim Neustart bewusst verworfen. */
export class InMemoryStagedSkillImports implements StagedSkillImports {
  private readonly entries = new Map<string, {entry: StagedSkillImport; stagedAt: number}>();

  constructor(private readonly lifetimeMs = defaultLifetimeMs, private readonly now: () => number = Date.now) {}

  stage(entry: StagedSkillImport): string {
    this.discardExpired();
    while (this.entries.size >= maximumStaged) this.entries.delete(this.entries.keys().next().value!);
    const importId = randomUUID();
    this.entries.set(importId, {entry, stagedAt: this.now()});
    return importId;
  }

  find(importId: string): StagedSkillImport | undefined {
    this.discardExpired();
    return this.entries.get(importId)?.entry;
  }

  discard(importId: string): void {
    this.entries.delete(importId);
  }

  private discardExpired(): void {
    for (const [importId, {stagedAt}] of this.entries) {
      if (this.now() - stagedAt > this.lifetimeMs) this.entries.delete(importId);
    }
  }
}
