import assert from "node:assert/strict";
import {createServer, type IncomingMessage, type Server} from "node:http";
import {type AddressInfo} from "node:net";
import {Readable} from "node:stream";
import test from "node:test";
import {HttpPythonInferenceSidecar} from "./http-python-inference-sidecar.js";
import {MlServiceHttp} from "./ml-service-http.js";
import {modelBundleFor} from "./model-artifact-bundle.js";
import {BundleFilesMissingError} from "./python-inference-sidecar.js";

const reference = {
  artifactId: "model", versionId: "1", format: "onnx" as const, contentType: "application/onnx", sizeBytes: 4, sha256: "a".repeat(64),
};

test("streams a team file with its length and checksum", async () => {
  await withServer({status: 201, body: {status: "received"}}, async (sidecar, requests) => {
    const bundle = modelBundleFor(reference);

    await sidecar.upload(bundle, bundle.files[0], () => Readable.from([Buffer.from("onnx")]));

    assert.equal(requests[0]?.url, `/v1/bundles/${bundle.key}/files/model.onnx`);
    assert.equal(requests[0]?.headers["content-length"], "4");
    assert.equal(requests[0]?.headers["x-sha256"], "a".repeat(64));
    assert.equal(requests[0]?.content, "onnx");
  });
});

test("sends store paths only for global models and reports missing team files", async () => {
  await withServer({status: 409, body: {code: "bundle_files_missing", missing: ["model.onnx"]}}, async (sidecar, requests) => {
    await assert.rejects(sidecar.load(modelBundleFor(reference), "team"), (error: unknown) =>
      error instanceof BundleFilesMissingError && error.missing.join() === "model.onnx");
    await assert.rejects(sidecar.load(modelBundleFor(reference), "global"));

    const [team, global] = requests.map((request) => JSON.parse(request.content) as {files: {storePath?: string}[]});
    assert.equal(team?.files[0]?.storePath, undefined);
    assert.equal(global?.files[0]?.storePath, "model-artifacts/model/versions/1/model.onnx");
  });
});

type Recorded = {url: string; headers: IncomingMessage["headers"]; content: string};
type Reply = {status: number; body: object};

async function withServer(
  reply: Reply,
  action: (sidecar: HttpPythonInferenceSidecar, requests: Recorded[]) => Promise<void>,
): Promise<void> {
  const requests: Recorded[] = [];
  const server: Server = createServer((request, response) => {
    void (async () => {
      const content = await text(request);
      requests.push({url: request.url ?? "", headers: request.headers, content});
      response.writeHead(reply.status, {"content-type": "application/json"}).end(JSON.stringify(reply.body));
    })();
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  try {
    const url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
    await action(new HttpPythonInferenceSidecar(new MlServiceHttp(url)), requests);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

async function text(stream: AsyncIterable<unknown>): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) chunks.push(Buffer.from(chunk as Uint8Array));
  return Buffer.concat(chunks).toString("utf8");
}
