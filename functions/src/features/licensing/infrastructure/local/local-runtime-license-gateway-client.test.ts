import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {
  LicenseActivationRejectedError,
  LicenseGatewayUnavailableError,
} from "../../domain/entities/runtime-license-errors.js";
import {HttpRuntimeLicenseGatewayClient} from "./local-runtime-license-gateway-client.js";

function stubFetch(t: TestContext, respond: () => Promise<Response>): void {
  const original = globalThis.fetch;
  globalThis.fetch = respond as typeof fetch;
  t.after(() => {globalThis.fetch = original;});
}

const gateway = () => new HttpRuntimeLicenseGatewayClient("https://gateway.example/issue");

test("a client error from the gateway means the token was rejected", async (t) => {
  stubFetch(t, async () => new Response(JSON.stringify({error: "abgelehnt"}), {status: 401}));
  await assert.rejects(gateway().activate("A3K9N7P2Q4R6T8W5"), LicenseActivationRejectedError);
});

test("a server error from the gateway means it is unavailable", async (t) => {
  stubFetch(t, async () => new Response("", {status: 503}));
  await assert.rejects(gateway().activate("A3K9N7P2Q4R6T8W5"), LicenseGatewayUnavailableError);
});

test("a network failure means the gateway is unavailable", async (t) => {
  stubFetch(t, async () => {throw new TypeError("fetch failed");});
  await assert.rejects(gateway().activate("A3K9N7P2Q4R6T8W5"), (error) =>
    error instanceof LicenseGatewayUnavailableError && error.causeDetail === "fetch failed");
});
