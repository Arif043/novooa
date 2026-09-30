import assert from "node:assert/strict";
import test from "node:test";
import {bootstrapLocalRuntime} from "./local-runtime-server-bootstrap.js";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {createRuntimeKeyring} from "../../features/runtime_security/infrastructure/runtime-keyring.js";
import {CurrentRuntimeFieldCipher} from "../../features/runtime_security/infrastructure/current-runtime-field-cipher.js";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";

test("starts the runtime HTTP server with the new keyring configuration", async () => {
  const database = new SqliteLocalSqlDatabase(":memory:");
  const {server, application} = await bootstrapLocalRuntime({
    database, runtimeRoot: "/unused", fieldCipher: new CurrentRuntimeFieldCipher(JSON.stringify(createRuntimeKeyring())),
    licenses: inactiveLicenses(), cors: LocalRuntimeCorsPolicy.fromEnvironment(), webFiles: undefined, port: 0,
  });
  try {
    const address = server.address();
    assert.ok(address && typeof address !== "string");
    const response = await fetch(`http://127.0.0.1:${address.port}/healthz`);
    assert.equal(response.status, 200);
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
    await application.stop();
    database.close();
  }
});

function inactiveLicenses(): RuntimeLicenseService {
  return {
    restore: async () => null,
    activate: async () => { throw new Error("Keine Test-Aktivierung."); },
    release: async () => {}, activeContext: () => null,
    signedActiveLicense: () => null, activeActivation: () => null,
    status: () => ({state: "notActivated"}),
  };
}
