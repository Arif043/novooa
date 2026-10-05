import {createHash} from "node:crypto";
import {parsePluginManifest, type PluginManifest} from "./plugin-manifest.js";
import {PluginPackageError} from "./plugin-package-error.js";

export type PluginFile = {path: string; bytes: Uint8Array};
export type PluginPackage = {manifest: PluginManifest; files: PluginFile[]};

export const pluginManifestFile = "plugin.json";
export const pluginSignatureFile = "SIGNATURE";

export const pluginPackageLimits = {
  maximumFiles: 200,
  maximumTotalBytes: 10 * 1024 * 1024,
} as const;

/** Prüft Pfade und Größen und liest das Manifest. Die Signatur prüft der Aufrufer über `pluginDigest`. */
export function pluginPackageFrom(files: readonly PluginFile[]): PluginPackage {
  if (files.length > pluginPackageLimits.maximumFiles) throw new PluginPackageError("Das Plugin enthält zu viele Dateien.");
  let total = 0;
  for (const file of files) {
    if (!isSafePath(file.path)) throw new PluginPackageError(`Ungültiger Dateipfad im Plugin: ${file.path}`);
    total += file.bytes.length;
  }
  if (total > pluginPackageLimits.maximumTotalBytes) throw new PluginPackageError("Das Plugin ist zu groß.");
  const manifestFile = files.find((file) => file.path === pluginManifestFile);
  if (manifestFile === undefined) throw new PluginPackageError("Im Plugin fehlt die plugin.json.");
  const manifest = parsePluginManifest(new TextDecoder().decode(manifestFile.bytes));
  if (!isSafePath(manifest.entry) || !files.some((file) => file.path === manifest.entry)) {
    throw new PluginPackageError(`Die Einstiegsdatei „${manifest.entry}“ fehlt im Plugin.`);
  }
  return {manifest, files: [...files]};
}

/**
 * Prüfsumme über alle Dateien außer der Signatur — Pfad und Inhalt, nach Pfad sortiert,
 * damit die Reihenfolge im ZIP keine Rolle spielt.
 */
export function pluginDigest(files: readonly PluginFile[]): Buffer {
  const lines = files
    .filter((file) => file.path !== pluginSignatureFile)
    .map((file) => `${file.path}\0${createHash("sha256").update(file.bytes).digest("hex")}\n`)
    .sort();
  return createHash("sha256").update(lines.join("")).digest();
}

function isSafePath(path: string): boolean {
  if (path.length === 0 || path.length > 300 || path.startsWith("/") || path.includes("\0") || path.includes("\\")) return false;
  const parts = path.split("/");
  return parts.every((part) => part !== "" && part !== "." && part !== ".." && part !== ".git" && part !== "node_modules");
}
