import {type PluginManifest} from "../entities/plugin-manifest.js";
import {PluginPackageError} from "../entities/plugin-package-error.js";
import {pluginDigest, pluginPackageFrom, pluginSignatureFile, type PluginFile} from "../entities/plugin-package.js";
import {type StoredPlugin} from "../entities/stored-plugin.js";
import {type PluginSignatureVerifier} from "../repositories/plugin-signature-verifier.js";
import {type PluginStore} from "../repositories/plugin-store.js";
import {type StagedPluginInstalls} from "../repositories/staged-plugin-installs.js";

export type PluginInstallPreview = {
  installId: string;
  manifest: PluginManifest;
  /** Bereits installierte Version, falls das Plugin ersetzt wird. */
  installedVersion?: string;
};

/** Prüft Paket und Signatur und legt es bis zur Bestätigung zurück — installiert wird erst im Commit. */
export class PreviewPluginInstall {
  constructor(
    private readonly store: PluginStore,
    private readonly verifier: PluginSignatureVerifier,
    private readonly staged: StagedPluginInstalls,
  ) {}

  async execute(files: readonly PluginFile[]): Promise<PluginInstallPreview> {
    const plugin = pluginPackageFrom(files);
    const signature = files.find((file) => file.path === pluginSignatureFile)?.bytes;
    if (!this.verifier.verify(pluginDigest(files), signature)) {
      throw new PluginPackageError("Die Signatur des Plugins ist ungültig oder fehlt. Es wird nicht installiert.");
    }
    const installed = await this.store.find(plugin.manifest.id);
    return {
      installId: this.staged.add(plugin),
      manifest: plugin.manifest,
      ...(installed === undefined ? {} : {installedVersion: installed.version}),
    };
  }
}

export class CommitPluginInstall {
  constructor(private readonly store: PluginStore, private readonly staged: StagedPluginInstalls) {}

  async execute(installId: string): Promise<StoredPlugin> {
    const plugin = this.staged.find(installId);
    if (plugin === undefined) throw new PluginPackageError("Die Installation ist abgelaufen. Bitte starte sie erneut.");
    const saved = await this.store.save(plugin);
    this.staged.discard(installId);
    return saved;
  }
}
