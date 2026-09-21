import assert from "node:assert/strict";
import test from "node:test";
import {runtimeFirebaseConfigurationFromEnvironment} from "./runtime-firebase-session.js";

test("uses a complete runtime Firebase configuration", () => {
  assert.deepEqual(runtimeFirebaseConfigurationFromEnvironment({
    LOCAL_RUNTIME_FIREBASE_API_KEY: "api-key",
    LOCAL_RUNTIME_FIREBASE_PROJECT_ID: "project-1",
    LOCAL_RUNTIME_FIREBASE_TOKEN_URL: "https://example.test/token",
  }), {
    apiKey: "api-key",
    projectId: "project-1",
    tokenEndpoint: "https://example.test/token",
  });
});

test("rejects a partial or insecure runtime Firebase configuration", () => {
  assert.throws(
    () => runtimeFirebaseConfigurationFromEnvironment({LOCAL_RUNTIME_FIREBASE_API_KEY: "api-key"}),
    /unvollständig/,
  );
  assert.throws(
    () => runtimeFirebaseConfigurationFromEnvironment({
      LOCAL_RUNTIME_FIREBASE_API_KEY: "api-key",
      LOCAL_RUNTIME_FIREBASE_PROJECT_ID: "project-1",
      LOCAL_RUNTIME_FIREBASE_TOKEN_URL: "http://example.test/token",
    }),
    /HTTPS/,
  );
});
