import assert from "node:assert/strict";
import test from "node:test";
import {mkdtemp, mkdir, writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import {LocalRuntimeStaticFiles} from "./local-runtime-static-files.js";

// Deckt die Auslieferung des Web-Builds durch die Runtime ab — der Kern der
// Same-Origin-Lösung. Wichtig sind vor allem die beiden Grenzen: kein
// Ausbruch aus dem Wurzelverzeichnis und keine Abschattung von API-Pfaden.

async function staticFilesWithBuild(): Promise<LocalRuntimeStaticFiles> {
  const root = await mkdtemp(join(tmpdir(), "novooa-web-"));
  await writeFile(join(root, "index.html"), "<html>novooa</html>");
  await writeFile(join(root, "main.dart.js"), "console.log(1)");
  await mkdir(join(root, "assets"), {recursive: true});
  await writeFile(join(root, "assets", "logo.png"), Buffer.from([1, 2, 3]));
  await writeFile(join(root, "..", "geheim.txt"), "nicht ausliefern");
  return new LocalRuntimeStaticFiles(root);
}

test("liefert index.html für die Wurzel", async () => {
  const files = await staticFilesWithBuild();

  const file = await files.find("GET", "/");

  assert.equal(file?.bytes.toString("utf8"), "<html>novooa</html>");
  assert.equal(file?.contentType, "text/html; charset=utf-8");
});

test("liefert Dateien mit passendem Content-Type", async () => {
  const files = await staticFilesWithBuild();

  assert.equal(
    (await files.find("GET", "/main.dart.js"))?.contentType,
    "text/javascript; charset=utf-8",
  );
  assert.equal(
    (await files.find("GET", "/assets/logo.png"))?.contentType,
    "image/png",
  );
});

test("ignoriert Query-Parameter beim Auflösen", async () => {
  const files = await staticFilesWithBuild();

  const file = await files.find("GET", "/main.dart.js?v=123");

  assert.equal(file?.bytes.toString("utf8"), "console.log(1)");
});

test("tiefe App-Routen fallen auf index.html zurück", async () => {
  const files = await staticFilesWithBuild();

  const file = await files.find("GET", "/aufgaben/42");

  assert.equal(file?.bytes.toString("utf8"), "<html>novooa</html>");
});

test("eine fehlende Datei mit Endung bleibt ein 404 statt HTML zu liefern", async () => {
  const files = await staticFilesWithBuild();

  assert.equal(await files.find("GET", "/fehlt.png"), null);
});

test("API-Pfade werden nie aus dem Dateisystem bedient", async () => {
  const files = await staticFilesWithBuild();

  assert.equal(await files.find("GET", "/v1/tasks"), null);
  assert.equal(await files.find("GET", "/healthz"), null);
});

test("Pfad-Traversal gibt niemals eine Datei ausserhalb der Wurzel preis", async () => {
  const files = await staticFilesWithBuild();

  // `..` wird bei absoluten Pfaden wegnormalisiert, der Zugriff landet also
  // gar nicht erst ausserhalb. Entscheidend ist, dass der Inhalt der
  // fremden Datei unter keinem dieser Pfade zurückkommt.
  for (const attempt of [
    "/../geheim.txt",
    "/../../etc/passwd",
    "/%2e%2e/geheim.txt",
    "/assets/../../geheim.txt",
  ]) {
    const file = await files.find("GET", attempt);
    const content = file?.bytes.toString("utf8") ?? "";
    assert.equal(
      content.includes("nicht ausliefern"),
      false,
      `${attempt} hat eine fremde Datei ausgeliefert`,
    );
  }
});

test("ein Ausbruchsversuch mit Dateiendung ist ein 404", async () => {
  const files = await staticFilesWithBuild();

  assert.equal(await files.find("GET", "/../geheim.txt"), null);
  assert.equal(await files.find("GET", "/%2e%2e/geheim.txt"), null);
});

test("nur GET und HEAD werden bedient", async () => {
  const files = await staticFilesWithBuild();

  assert.equal(await files.find("POST", "/index.html"), null);
  assert.equal(await files.find("DELETE", "/"), null);
  assert.notEqual(await files.find("HEAD", "/"), null);
});
