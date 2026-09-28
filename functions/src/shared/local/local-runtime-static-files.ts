import {readFile} from "node:fs/promises";
import {extname, join, normalize, resolve, sep} from "node:path";

export type LocalRuntimeStaticFile = {
  bytes: Buffer;
  contentType: string;
};

/**
 * Liefert das Flutter-Web-Build der Runtime aus, damit die App unter
 * derselben Herkunft läuft wie ihre API (siehe
 * `docs/architecture/betriebsvarianten.md`). Dadurch entfallen CORS und
 * Mixed Content vollständig.
 *
 * Liegt bewusst **außerhalb** der Lizenz- und Session-Middleware: Die App muss
 * gerade *vor* Aktivierung und Anmeldung laden können — sonst gäbe es keine
 * Oberfläche, um beides durchzuführen.
 */
export class LocalRuntimeStaticFiles {
  constructor(private readonly root: string) {}

  async find(method: string, url: string): Promise<LocalRuntimeStaticFile | null> {
    if (method !== "GET" && method !== "HEAD") return null;
    const requested = pathnameOf(url);
    // API-Pfade nie aus dem Dateisystem bedienen — sonst könnte eine Datei
    // einen fehlenden Endpunkt maskieren und 404 zu 200 machen.
    if (requested.startsWith("/v1/") || requested === "/healthz") return null;
    return await this.fileAt(requested) ?? await this.indexFallback(requested);
  }

  private async fileAt(pathname: string): Promise<LocalRuntimeStaticFile | null> {
    const target = this.resolveWithinRoot(pathname);
    if (target === null) return null;
    try {
      return {bytes: await readFile(target), contentType: contentTypeFor(target)};
    } catch {
      return null;
    }
  }

  /**
   * Single-Page-App: Tiefe Routen wie `/aufgaben/42` existieren nicht als
   * Datei, sollen aber die App laden statt 404 zu liefern. Anfragen mit
   * Dateiendung sind davon ausgenommen — ein fehlendes Bild soll ein 404
   * bleiben und nicht als HTML zurückkommen.
   */
  private async indexFallback(pathname: string): Promise<LocalRuntimeStaticFile | null> {
    if (extname(pathname) !== "") return null;
    return this.fileAt("/index.html");
  }

  /**
   * Verhindert Pfad-Traversal (`../../etc/passwd`): Der aufgelöste Pfad muss
   * innerhalb des Wurzelverzeichnisses liegen.
   */
  private resolveWithinRoot(pathname: string): string | null {
    const root = resolve(this.root);
    const target = resolve(join(root, normalize(pathname)));
    if (target !== root && !target.startsWith(root + sep)) return null;
    return target;
  }
}

function pathnameOf(url: string): string {
  const withoutQuery = url.split("?")[0].split("#")[0];
  const decoded = safeDecode(withoutQuery);
  return decoded === "/" || decoded === "" ? "/index.html" : decoded;
}

function safeDecode(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

const contentTypes: Readonly<Record<string, string>> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".wasm": "application/wasm",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".webp": "image/webp",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".map": "application/json; charset=utf-8",
};

function contentTypeFor(target: string): string {
  return contentTypes[extname(target).toLowerCase()] ?? "application/octet-stream";
}
