import {type LocalRuntimeRequest} from "./local-runtime-http-server.js";

/**
 * Die Parameternamen eines Routenmusters, aus dem Muster selbst abgeleitet.
 * `"/v1/files/:fileId/versions/:versionId"` ergibt `"fileId" | "versionId"`.
 *
 * Dadurch ist `match.params.fileId` typgeprüft und ein Tippfehler ein
 * Compile-Fehler — was die vorherigen Regexe mit ihren namenlosen
 * `match[1]`/`match[2]` nicht leisten konnten.
 */
type PathParameter<Pattern extends string> =
  Pattern extends `${string}:${infer Name}/${infer Rest}`
    ? Name | PathParameter<`/${Rest}`>
    : Pattern extends `${string}:${infer Name}`
      ? Name
      : never;

export type RouteMatch<Pattern extends string> = {
  params: Record<PathParameter<Pattern>, string>;
};

/**
 * Prüft, ob eine Anfrage auf ein Routenmuster passt, und liefert die
 * Pfadparameter zurück — `null`, wenn nicht.
 *
 * Ersetzt die zuvor je Handler von Hand gebauten regulären Ausdrücke.
 * Query-Strings werden abgeschnitten, Parameterwerte URL-dekodiert; leere
 * Segmente passen nie (`/v1/files//versions/x` ist kein Treffer).
 */
export function routeMatch<Pattern extends string>(
  request: LocalRuntimeRequest,
  method: string,
  pattern: Pattern,
): RouteMatch<Pattern> | null {
  if (request.method !== method) return null;
  const path = pathnameOf(request.url ?? "");
  const patternSegments = segmentsOf(pattern);
  const pathSegments = segmentsOf(path);
  if (patternSegments.length !== pathSegments.length) return null;
  const params: Record<string, string> = {};
  for (const [index, expected] of patternSegments.entries()) {
    const actual = pathSegments[index];
    if (expected.startsWith(":")) {
      if (actual.length === 0) return null;
      params[expected.slice(1)] = safeDecode(actual);
      continue;
    }
    if (expected !== actual) return null;
  }
  return {params} as RouteMatch<Pattern>;
}

function segmentsOf(path: string): string[] {
  return path.replace(/\/+$/, "").split("/");
}

function pathnameOf(url: string): string {
  return url.split("?")[0].split("#")[0];
}

function safeDecode(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}
