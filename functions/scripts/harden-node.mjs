import {build} from "esbuild";
import JavaScriptObfuscator from "javascript-obfuscator";
import {mkdir, readFile, rm, stat, writeFile} from "node:fs/promises";
import {dirname, join, resolve} from "node:path";
import {fileURLToPath} from "node:url";
import {obfuscatorOptions} from "./node-protection-options.mjs";

const functionsRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const libDirectory = join(functionsRoot, "lib");
const outputDirectory = join(functionsRoot, "dist-protected");

// Pfade bleiben wie in Compose: __dirname findet Migrationen und öffentliche Schlüssel.
const entrypoints = [
  "shared/local/local-runtime-entrypoint.js",
  "shared/local/local-runtime-keyring-init-cli.js",
  "shared/local/local-runtime-key-rotation-cli.js",
];

async function bundleEntrypoints() {
  await build({
    entryPoints: entrypoints.map((entry) => join(libDirectory, entry)),
    outbase: libDirectory,
    outdir: outputDirectory,
    bundle: true,
    platform: "node",
    format: "cjs",
    target: "node24",
    minify: true,
    keepNames: true,
    legalComments: "none",
    packages: "external",
    logLevel: "warning",
  });
}

async function obfuscateEntrypoint(entry) {
  const file = join(outputDirectory, entry);
  const source = await readFile(file, "utf8");
  const protectedSource = JavaScriptObfuscator.obfuscate(source, obfuscatorOptions).getObfuscatedCode();
  await writeFile(file, protectedSource, "utf8");
  console.log(`gehärtet: ${entry} (${Buffer.byteLength(source)} → ${Buffer.byteLength(protectedSource)} Bytes)`);
}

async function main() {
  if (!(await stat(libDirectory)).isDirectory()) throw new Error("Zuerst npm run build ausführen.");
  await rm(outputDirectory, {recursive: true, force: true});
  await mkdir(outputDirectory, {recursive: true});
  await bundleEntrypoints();
  for (const entry of entrypoints) await obfuscateEntrypoint(entry);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
