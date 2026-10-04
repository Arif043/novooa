// Härtet die Node-Container-Entrypoints gegen Reverse-Engineering: esbuild
// bündelt je Entrypoint den gesamten eigenen Code aus lib/ in eine einzige
// Datei (node_modules bleiben extern — unser Code ist das Schützenswerte, nicht
// die Abhängigkeiten), danach verschleiert javascript-obfuscator das Bündel.
// Nur diese Bündel wandern ins Image; der restliche, gut lesbare lib/-Baum
// entfällt dort.
//
// WARUM in-place am selben lib-Pfad: Der Runtime-Entrypoint löst Pfade relativ
// zu `__dirname` auf (Migrationsverzeichnis). Die Bündel behalten deshalb ihre
// Pfadtiefe unter lib/, damit `__dirname` im Container unverändert bleibt.
//
// Verschleierung erhöht die Kosten des Reverse-Engineering, macht es aber nicht
// unmöglich: Code, der beim Kunden läuft, ist grundsätzlich analysierbar. Der
// eigentliche Diebstahlschutz ist das Lizenzsystem (signierte Lizenz +
// Public-Key-Prüfung + Gateway), siehe docs/local-runtime-schutz.md.

import { build } from "esbuild";
import JavaScriptObfuscator from "javascript-obfuscator";
import { readFile, writeFile, rm, mkdir, stat } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const functionsRoot = resolve(here, "..");
const libDir = join(functionsRoot, "lib");
const outDir = join(functionsRoot, "dist-protected");

// Container-Entrypoints (relativ zu lib/). Nur was in docker-compose.local.yaml
// bzw. in den Dockerfiles als Prozess startet — CLI-Hilfswerkzeuge für die
// Entwicklung gehören nicht ins ausgelieferte Image.
const entrypoints = [
  "shared/local/local-runtime-entrypoint.js",
  "shared/local/local-runtime-keyring-seed-cli.js",
  "shared/local/local-runtime-key-rotation-cli.js",
  "features/machine_learning/infrastructure/model-inference-service.js",
];

// Server-sichere, aber kräftige Verschleierung. Bewusst AUS: selfDefending und
// debugProtection (zielen auf Browser-DevTools, erzeugen serverseitig nur
// Absturzrisiko) sowie disableConsoleOutput (die Runtime loggt über die
// Konsole). stringArrayEncoding base64 statt rc4 — rc4 kostet spürbar Laufzeit
// bei gleichem Schutz gegen simples Mitlesen.
const obfuscatorOptions = {
  target: "node",
  compact: true,
  controlFlowFlattening: true,
  controlFlowFlatteningThreshold: 0.75,
  deadCodeInjection: true,
  deadCodeInjectionThreshold: 0.2,
  numbersToExpressions: true,
  simplify: true,
  splitStrings: true,
  splitStringsChunkLength: 8,
  stringArray: true,
  stringArrayCallsTransform: true,
  // rc4 statt base64: Strings (inkl. eingebettetem Public Key) werden
  // verschlüsselt statt nur base64-kodiert abgelegt. Hinweis: Ein Public Key
  // ist nicht geheim — das erschwert nur das Mitlesen, es ist kein Ersatz für
  // die Signaturprüfung. rc4 kostet etwas mehr Laufzeit als base64.
  stringArrayEncoding: ["rc4"],
  stringArrayRotate: true,
  stringArrayShuffle: true,
  stringArrayThreshold: 0.8,
  transformObjectKeys: true,
  identifierNamesGenerator: "mangled-shuffled",
  // selfDefending: bricht bei Formatierungs-/Beautify-Versuchen.
  // debugProtection: erschwert das Anhängen eines Debuggers. Ohne
  // debugProtectionInterval (Standard aus), damit kein Dauer-Timer den
  // Event-Loop belastet. Beide zielen primär auf manuelle Analyse; auf einem
  // Server, den die Kundschaft selbst kontrolliert, ist der Nutzen begrenzt,
  // der Laufzeitpfad bleibt aber unberührt (siehe Lasttest im Build).
  selfDefending: true,
  debugProtection: true,
  disableConsoleOutput: false,
};

async function main() {
  const libExists = await stat(libDir).then(
    (s) => s.isDirectory(),
    () => false,
  );
  if (!libExists) {
    throw new Error(
      `lib/ fehlt unter ${libDir}. Zuerst \`npm run build\` ausführen.`,
    );
  }

  await rm(outDir, { recursive: true, force: true });
  await mkdir(outDir, { recursive: true });

  // 1) Bündeln: eigener Code inline, node_modules extern (require bleibt wie in
  //    der unveränderten lib/ — identisches Laufzeit-Modulverhalten).
  await build({
    entryPoints: entrypoints.map((e) => join(libDir, e)),
    outbase: libDir,
    outdir: outDir,
    bundle: true,
    platform: "node",
    format: "cjs",
    target: "node24",
    minify: true,
    legalComments: "none",
    packages: "external",
    logLevel: "warning",
  });

  // 2) Verschleiern: jedes Bündel in-place.
  for (const entry of entrypoints) {
    const file = join(outDir, entry);
    const source = await readFile(file, "utf8");
    const before = Buffer.byteLength(source);
    const obfuscated = JavaScriptObfuscator.obfuscate(
      source,
      obfuscatorOptions,
    ).getObfuscatedCode();
    await writeFile(file, obfuscated, "utf8");
    const after = Buffer.byteLength(obfuscated);
    console.log(
      `gehärtet: ${entry}  (${(before / 1024).toFixed(0)} kB → ${(after / 1024).toFixed(0)} kB)`,
    );
  }

  console.log(`\nFertig. Gehärtete Bündel unter ${outDir}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
