import {randomUUID} from "node:crypto";
import {type PluginPackage} from "../../domain/entities/plugin-package.js";
import {type StagedPluginInstalls} from "../../domain/repositories/staged-plugin-installs.js";

const lifetimeMilliseconds = 15 * 60 * 1000;

export class InMemoryStagedPluginInstalls implements StagedPluginInstalls {
  private readonly entries = new Map<string, {plugin: PluginPackage; expiresAt: number}>();

  constructor(private readonly now: () => number = Date.now) {}

  add(plugin: PluginPackage): string {
    this.sweep();
    const installId = randomUUID();
    this.entries.set(installId, {plugin, expiresAt: this.now() + lifetimeMilliseconds});
    return installId;
  }

  find(installId: string): PluginPackage | undefined {
    this.sweep();
    return this.entries.get(installId)?.plugin;
  }

  discard(installId: string): void {
    this.entries.delete(installId);
  }

  private sweep(): void {
    for (const [id, entry] of this.entries) if (entry.expiresAt <= this.now()) this.entries.delete(id);
  }
}
