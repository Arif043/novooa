import assert from "node:assert/strict";
import test from "node:test";
import {s3ModelStoreConfigurationFromEnvironment} from "./s3-model-object-store.js";

const required = {
  MODEL_STORE_S3_ENDPOINT: "https://s3.example.com", MODEL_STORE_S3_BUCKET: "novooa-models",
  MODEL_STORE_S3_ACCESS_KEY_ID: "GK123", MODEL_STORE_S3_SECRET_ACCESS_KEY: "geheim",
};

test("defaults to the Garage region and path-style addressing", () => {
  const configuration = s3ModelStoreConfigurationFromEnvironment(required);

  assert.equal(configuration.region, "garage");
  assert.equal(configuration.forcePathStyle, true);
});

test("takes the region from garage.toml and allows virtual-hosted buckets", () => {
  const configuration = s3ModelStoreConfigurationFromEnvironment({
    ...required, MODEL_STORE_S3_REGION: "eu-central", MODEL_STORE_S3_FORCE_PATH_STYLE: "false",
  });

  assert.equal(configuration.region, "eu-central");
  assert.equal(configuration.forcePathStyle, false);
});

test("names a missing setting", () => {
  assert.throws(() => s3ModelStoreConfigurationFromEnvironment({...required, MODEL_STORE_S3_BUCKET: " "}), /MODEL_STORE_S3_BUCKET fehlt/);
});
