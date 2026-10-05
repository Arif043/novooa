#!/usr/bin/env node
// Werkzeug für Plugin-Herausgeber (Admin). Vorher `npm run build`, weil Prüfsumme und Validierung aus lib/ kommen.
//
//   node scripts/plugin-tool.mjs generate-key <ordner>
//   node scripts/plugin-tool.mjs pack    <plugin-ordner> --key <private.pem> [--out <datei.zip>]
//   node scripts/plugin-tool.mjs publish <plugin-ordner> --key <private.pem> [--project <firebase-projekt>]
//
// `publish` braucht Application-Default-Credentials mit Schreibrechten auf Storage und Firestore.
import {generateKeyPairSync, createPrivateKey, sign} from "node:crypto";
import {mkdirSync, readdirSync, readFileSync, statSync, writeFileSync} from "node:fs";
import path from "node:path";
import {zipSync} from "fflate";
import {pluginDigest, pluginPackageFrom, pluginSignatureFile} from "../lib/features/plugins/domain/entities/plugin-package.js";

const [command, target, ...rest] = process.argv.slice(2);
const option = (name) => {
  const index = rest.indexOf(`--${name}`);
  return index >= 0 ? rest[index + 1] : undefined;
};

function fail(message) {
  console.error(message);
  process.exit(1);
}

function readTree(root, relative = "") {
  return readdirSync(path.join(root, relative)).flatMap((name) => {
    const entry = relative === "" ? name : `${relative}/${name}`;
    const full = path.join(root, entry);
    if (statSync(full).isDirectory()) return name === "node_modules" || name === ".git" ? [] : readTree(root, entry);
    return name === pluginSignatureFile ? [] : [{path: entry, bytes: new Uint8Array(readFileSync(full))}];
  });
}

function signedPackage(folder) {
  const keyFile = option("key");
  if (!keyFile) fail("Gib den privaten Schlüssel mit --key <private.pem> an.");
  const files = readTree(folder);
  const plugin = pluginPackageFrom(files);
  const signature = sign(null, pluginDigest(files), createPrivateKey(readFileSync(keyFile)));
  const all = [...files, {path: pluginSignatureFile, bytes: new Uint8Array(signature)}];
  const zip = zipSync(Object.fromEntries(all.map((file) => [file.path, file.bytes])));
  return {manifest: plugin.manifest, zip};
}

if (command === "generate-key" && target) {
  const {privateKey, publicKey} = generateKeyPairSync("ed25519");
  mkdirSync(target, {recursive: true});
  writeFileSync(path.join(target, "plugin-private.pem"), privateKey.export({type: "pkcs8", format: "pem"}), {mode: 0o600});
  writeFileSync(path.join(target, "plugin-public.pem"), publicKey.export({type: "spki", format: "pem"}));
  console.log(`Schlüsselpaar in ${target} angelegt. Der private Schlüssel gehört nicht ins Repository.`);
  console.log("Den öffentlichen Schlüssel setzt du in der Runtime als NOVOOA_PLUGIN_PUBLIC_KEY.");
} else if (command === "pack" && target) {
  const {manifest, zip} = signedPackage(target);
  const out = option("out") ?? `${manifest.id}-${manifest.version}.zip`;
  writeFileSync(out, zip);
  console.log(`${out} geschrieben (${zip.length} Bytes).`);
} else if (command === "publish" && target) {
  const {manifest, zip} = signedPackage(target);
  const {initializeApp} = await import("firebase-admin/app");
  const {getStorage} = await import("firebase-admin/storage");
  const {getFirestore} = await import("firebase-admin/firestore");
  const project = option("project");
  initializeApp(project ? {projectId: project} : undefined);
  await getStorage().bucket().file(`plugins/${manifest.id}/${manifest.version}/package.zip`).save(Buffer.from(zip), {contentType: "application/zip"});
  await getFirestore().collection("pluginCatalog").doc(manifest.id).set({
    name: manifest.name, description: manifest.description, version: manifest.version, sizeBytes: zip.length, publishedAt: new Date(),
  });
  console.log(`${manifest.name} ${manifest.version} veröffentlicht.`);
} else {
  fail("Verwendung: plugin-tool.mjs generate-key|pack|publish <ziel> [--key …] [--out …] [--project …]");
}
