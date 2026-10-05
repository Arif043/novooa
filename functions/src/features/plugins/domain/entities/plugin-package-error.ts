/** Das Plugin-Paket ist unbrauchbar (kein ZIP, ungültiges Manifest, falsche Signatur, zu groß). */
export class PluginPackageError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PluginPackageError";
  }
}
