import assert from "node:assert/strict";
import {createServer, type IncomingHttpHeaders} from "node:http";
import {type AddressInfo} from "node:net";
import test from "node:test";
import {type MlServiceCredentials, MlServiceHttp} from "./ml-service-http.js";

type Reply = {status: number; body: object; headers?: Record<string, string>};

test("sends the authorization and renews it once after 401", async () => {
  const credentials = new CountingCredentials();
  await withServer([{status: 401, body: {code: "unauthorized"}}, {status: 200, body: {ok: true}}], async (url, headers) => {
    const payload = await new MlServiceHttp(url, credentials).post("/v1/inferences", "{}");

    assert.deepEqual(payload, {ok: true});
    assert.deepEqual(headers.map((header) => header.authorization), ["Bearer 1", "Bearer 2"]);
    assert.deepEqual(credentials.rejected, ["Bearer 1"]);
  });
});

test("retries while the service is busy and gives up after the maximum wait", async () => {
  const busy = {status: 429, body: {code: "busy", error: "Der ML-Dienst ist ausgelastet."}, headers: {"retry-after": "0"}};
  const waits: number[] = [];
  const policy = {maximumWaitMs: 25, initialDelayMs: 10, maximumDelayMs: 10};
  await withServer([busy, busy, {status: 200, body: {ok: true}}], async (url) => {
    const http = new MlServiceHttp(url, undefined, policy, async (ms) => { waits.push(ms); });

    assert.deepEqual(await http.post("/v1/inferences", "{}"), {ok: true});
    assert.deepEqual(waits, [10, 10]);
  });
  await withServer([busy, busy, busy, busy], async (url) => {
    const http = new MlServiceHttp(url, undefined, {...policy, maximumWaitMs: 0}, async () => {});

    await assert.rejects(http.post("/v1/inferences", "{}"), /ausgelastet/);
  });
});

class CountingCredentials implements MlServiceCredentials {
  readonly rejected: string[] = [];
  private token = 1;

  async authorization(): Promise<string> {
    return `Bearer ${this.token}`;
  }

  async renew(rejected: string): Promise<void> {
    this.rejected.push(rejected);
    this.token += 1;
  }
}

async function withServer(replies: Reply[], action: (url: string, headers: IncomingHttpHeaders[]) => Promise<void>): Promise<void> {
  const headers: IncomingHttpHeaders[] = [];
  const server = createServer((request, response) => {
    headers.push(request.headers);
    const reply = replies[Math.min(headers.length - 1, replies.length - 1)];
    request.resume();
    response.writeHead(reply.status, {"content-type": "application/json", ...reply.headers}).end(JSON.stringify(reply.body));
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  try {
    await action(`http://127.0.0.1:${(server.address() as AddressInfo).port}`, headers);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}
