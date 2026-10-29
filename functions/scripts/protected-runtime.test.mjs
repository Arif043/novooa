// Im gebauten Runtime-Image ausführen; benötigt root nur für den Schlüssel-Init.
import assert from "node:assert/strict";
import {spawn, execFile} from "node:child_process";
import {once} from "node:events";
import {chown, mkdtemp, readFile, readdir, rm, stat} from "node:fs/promises";
import {join} from "node:path";
import {promisify} from "node:util";
import {setTimeout as delay} from "node:timers/promises";
import test from "node:test";

const execute = promisify(execFile);
const entryDirectory = "/app/functions/lib/shared/local";

async function runCommand(entry, environment, identity = {}) {
  return execute(process.execPath, [join(entryDirectory, entry)], {env: environment, ...identity});
}

async function waitForHealth(runtime) {
  for (let attempt = 0; attempt < 40; attempt++) {
    assert.equal(runtime.exitCode, null, "Runtime ist vorzeitig beendet worden.");
    const response = await fetch("http://127.0.0.1:8080/healthz").catch(() => null);
    if (response?.ok) return;
    await delay(250);
  }
  throw new Error("Runtime wurde nicht gesund.");
}

async function withRuntime(environment, check) {
  const runtime = spawn(process.execPath, [join(entryDirectory, "local-runtime-entrypoint.js")], {
    env: environment, uid: 1000, gid: 1000, stdio: ["ignore", "inherit", "inherit"],
  });
  try {
    await waitForHealth(runtime);
    await check();
  } finally {
    if (runtime.exitCode === null) {
      const closed = once(runtime, "exit");
      runtime.kill("SIGTERM");
      await closed;
    }
  }
}

/** Ohne Lizenz gibt es keinen Weg in die API — auch nicht in die Einrichtung. */
async function checkRoutes() {
  for (const path of ["/v1/setup", "/v1/tasks"]) {
    const response = await fetch(`http://127.0.0.1:8080${path}`);
    assert.equal(response.status, 423, `${path} muss ohne Lizenz gesperrt sein.`);
    assert.equal((await response.json()).licenseStatus, "notActivated");
  }
  if (process.env.LOCAL_RUNTIME_WEB_DIRECTORY) await checkWebApplication();
}

async function checkWebApplication() {
  const page = await fetch("http://127.0.0.1:8080/");
  assert.equal(page.status, 200);
  assert.match(await page.text(), /<title>novooa<\/title>/);
  for (const asset of ["flutter_bootstrap.js", "main.dart.js"]) {
    const response = await fetch(`http://127.0.0.1:8080/${asset}`);
    assert.equal(response.status, 200);
    assert.match(response.headers.get("content-type"), /javascript/);
  }
  const files = await readdir(process.env.LOCAL_RUNTIME_WEB_DIRECTORY, {recursive: true});
  assert.equal(files.some((file) => file.endsWith(".map")), false);
}

async function checkKeyInitialization(environment) {
  await runCommand("local-runtime-keyring-init-cli.js", environment);
  const keyFile = environment.LOCAL_RUNTIME_MASTER_KEY_FILE;
  const keyring = JSON.parse(await readFile(keyFile, "utf8"));
  const metadata = await stat(keyFile);
  assert.equal(metadata.uid, 1000);
  assert.equal(metadata.mode & 0o777, 0o600);
  await runCommand("local-runtime-keyring-init-cli.js", environment);
  assert.equal(JSON.parse(await readFile(keyFile, "utf8")).activeKeyId, keyring.activeKeyId);
  return keyring;
}

async function checkRuntime(environment) {
  const initialKeyring = await checkKeyInitialization(environment);
  await withRuntime(environment, checkRoutes);
  await runCommand("local-runtime-key-rotation-cli.js", environment, {uid: 1000, gid: 1000});
  const rotated = JSON.parse(await readFile(environment.LOCAL_RUNTIME_MASTER_KEY_FILE, "utf8"));
  assert.notEqual(rotated.activeKeyId, initialKeyring.activeKeyId);
  assert.equal(Object.keys(rotated.keys).length, 2);
  await withRuntime(environment, checkRoutes);
}

test("gehärtete Runtime startet, migriert, schützt Routen und übersteht Schlüsselrotation", {timeout: 60000}, async () => {
  assert.equal(process.getuid(), 0, "Container mit --user 0 starten.");
  assert.equal((await readdir(entryDirectory)).length, 3, "Nur drei Bündel dürfen ausgeliefert werden.");
  await assert.rejects(stat("/app/functions/keys"), "Der Lizenzschlüssel steckt im Bündel, nicht als Datei.");
  const root = await mkdtemp("/tmp/novooa-protected-check-");
  await chown(root, 1000, 1000);
  try {
    await checkRuntime({
      ...process.env, LOCAL_RUNTIME_ROOT: root, LOCAL_RUNTIME_MASTER_KEY_FILE: join(root, "keys/keyring.json"),
      // Ohne Lizenz startet die Runtime unaktiviert; das Gateway wird dafür nicht gebraucht.
      LOCAL_RUNTIME_LICENSE_GATEWAY_URL: "https://127.0.0.1:9/unerreichbar", HOST: "127.0.0.1", PORT: "8080",
    });
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});
