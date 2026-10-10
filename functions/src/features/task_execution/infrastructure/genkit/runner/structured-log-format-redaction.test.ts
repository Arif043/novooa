import assert from "node:assert/strict";
import test from "node:test";
import {formatConfig, redactedConfig} from "./structured-log-format-utils.js";
import {nodeAttributes} from "./structured-log-format.js";

const http = {
  primitive: "httpRequest", method: "POST", connectionId: "c1",
  url: "https://api.example.com/x?api_key=GEHEIM&page=2&access_token=T0K3N",
  query: [{name: "page", value: "2"}, {name: "api_key", value: "GEHEIM"}, {name: "Token", value: "GEHEIM2"}],
  headers: [{name: "Authorization", value: "Bearer GEHEIM"}, {name: "X-Anything", value: "auch geheim"}],
  bodyType: "json", body: '{"password":"GEHEIM"}', timeoutSeconds: 30, failOnHttpError: true,
};

test("HTTP-Anfragen: Header-Werte, Body und Zugangs-Parameter erscheinen nie im Log", () => {
  const redacted = redactedConfig(http) as typeof http;

  assert.equal(redacted.url, "https://api.example.com/x?api_key=•••&page=2&access_token=•••");
  assert.deepEqual(redacted.query, [{name: "page", value: "2"}, {name: "api_key", value: "•••"}, {name: "Token", value: "•••"}]);
  assert.deepEqual(redacted.headers, [{name: "Authorization", value: "•••"}, {name: "X-Anything", value: "•••"}]);
  assert.equal(redacted.body, "••• (21 Zeichen)");
  assert.equal(redacted.connectionId, "c1");
  for (const rendered of [formatConfig(http), JSON.stringify(nodeAttributes({id: "n", primitive: "httpRequest", title: "t", description: "", outputs: [], config: http} as never))]) {
    assert.equal(rendered.includes("GEHEIM"), false);
    assert.equal(rendered.includes("T0K3N"), false);
  }
});

test("andere Bausteine und leere Felder bleiben unverändert", () => {
  const prompt = {primitive: "prompt", instruction: "Fasse zusammen"};
  assert.equal(redactedConfig(prompt), prompt);
  assert.equal((redactedConfig({...http, body: ""}) as typeof http).body, "");
});
