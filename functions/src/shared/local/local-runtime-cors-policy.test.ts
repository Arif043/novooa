import assert from "node:assert/strict";
import test from "node:test";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";

// Deckt ab, dass die Runtime standardmäßig keine fremde Browser-Herkunft
// zulässt und sich nur durch ausdrückliche Konfiguration öffnet — nötig
// allein für die lokale Entwicklung.

test("ohne Konfiguration ist keine fremde Herkunft erlaubt", () => {
  const cors = LocalRuntimeCorsPolicy.fromEnvironment(undefined);

  assert.equal(cors.allows("http://localhost:59193", "192.168.1.42:8090"), false);
  assert.equal(cors.headersFor("http://localhost:59193"), null);
});

test("eine leere Konfiguration öffnet nichts", () => {
  const cors = LocalRuntimeCorsPolicy.fromEnvironment("   ");

  assert.equal(cors.allows("http://localhost:59193", "192.168.1.42:8090"), false);
});

test("ohne Origin — also kein Browser — wird durchgelassen", () => {
  const cors = LocalRuntimeCorsPolicy.fromEnvironment(undefined);

  assert.equal(cors.allows(undefined, "192.168.1.42:8090"), true);
  assert.equal(cors.allows("", "192.168.1.42:8090"), true);
});

test("Same Origin ist immer erlaubt — der vorgesehene Betrieb", () => {
  const cors = LocalRuntimeCorsPolicy.fromEnvironment(undefined);

  assert.equal(cors.allows("http://192.168.1.42:8090", "192.168.1.42:8090"), true);
  assert.equal(cors.allows("https://novooa.example.de", "novooa.example.de"), true);
});

test("Same Origin braucht keine CORS-Header", () => {
  const cors = LocalRuntimeCorsPolicy.fromEnvironment(undefined);

  assert.equal(cors.headersFor("http://192.168.1.42:8090"), null);
});

test("eine konfigurierte Herkunft wird erlaubt und bekommt Header", () => {
  const cors = LocalRuntimeCorsPolicy.fromEnvironment("http://localhost:59193");

  assert.equal(cors.allows("http://localhost:59193", "127.0.0.1:8090"), true);
  const headers = cors.headersFor("http://localhost:59193");
  assert.equal(headers?.["access-control-allow-origin"], "http://localhost:59193");
  assert.equal(headers?.vary, "Origin", "sonst könnte ein Cache die Freigabe verwechseln");
  assert.match(headers?.["access-control-allow-headers"] ?? "", /authorization/);
});

test("mehrere Herkünfte lassen sich kommagetrennt konfigurieren", () => {
  const cors = LocalRuntimeCorsPolicy.fromEnvironment(
    "http://localhost:59193, http://localhost:8080",
  );

  assert.equal(cors.allows("http://localhost:59193", "x"), true);
  assert.equal(cors.allows("http://localhost:8080", "x"), true);
  assert.equal(cors.allows("http://boese.example", "x"), false);
});

test("eine nicht konfigurierte Herkunft bekommt niemals Header", () => {
  const cors = LocalRuntimeCorsPolicy.fromEnvironment("http://localhost:59193");

  assert.equal(cors.headersFor("http://boese.example"), null);
  assert.equal(cors.allows("http://boese.example", "127.0.0.1:8090"), false);
});

test("es gibt kein pauschales Sternchen", () => {
  const cors = LocalRuntimeCorsPolicy.fromEnvironment("*");

  assert.equal(
    cors.allows("http://boese.example", "127.0.0.1:8090"),
    false,
    "'*' ist nur ein gewöhnlicher, nie passender Eintrag",
  );
});
