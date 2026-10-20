import assert from "node:assert/strict";
import test from "node:test";
import {TokenBucketRateLimiter} from "../rate_limiting/domain/usecases/token-bucket-rate-limiter.js";
import {InMemoryBucketStateStore} from "../rate_limiting/infrastructure/local/in-memory-bucket-state-store.js";
import {StagedLoginLimiter} from "./local-runtime-login-rate-limiter.js";

function limiter(perClientCapacity: number, globalCapacity: number, perAccountCapacity = 100) {
  // Eingefrorene Uhr: Kein Token wächst während des Tests nach.
  const now = Date.now();
  const bucket = (capacity: number) => new TokenBucketRateLimiter(
    new InMemoryBucketStateStore(), {current: async () => ({capacity, refillPerSecond: 1 / 60})}, () => now,
  );
  return new StagedLoginLimiter(bucket(perClientCapacity), bucket(perAccountCapacity), bucket(globalCapacity));
}

test("limits attempts per client", async () => {
  const login = limiter(2, 100);
  assert.equal((await login.take({client: "10.0.0.1"})).allowed, true);
  assert.equal((await login.take({client: "10.0.0.1"})).allowed, true);
  const third = await login.take({client: "10.0.0.1"});
  assert.equal(third.allowed, false);
  assert.ok(third.retryAfterSeconds > 0);
  assert.equal((await login.take({client: "10.0.0.2"})).allowed, true, "ein anderer Client ist nicht betroffen");
});

test("caps attempts across all clients", async () => {
  const login = limiter(5, 3);
  for (const client of ["a", "b", "c"]) assert.equal((await login.take({client: client})).allowed, true);
  assert.equal((await login.take({client: "d"})).allowed, false);
});

test("a client blocked by its own limit does not use up the global budget", async () => {
  const login = limiter(1, 2);
  await login.take({client: "laut"});
  for (let attempt = 0; attempt < 10; attempt += 1) await login.take({client: "laut"});
  assert.equal((await login.take({client: "leise"})).allowed, true);
});

test("limits attempts per account across clients", async () => {
  const login = limiter(100, 100, 2);
  assert.equal((await login.take({client: "a", account: "anna"})).allowed, true);
  assert.equal((await login.take({client: "b", account: "anna"})).allowed, true);
  assert.equal((await login.take({client: "c", account: "anna"})).allowed, false);
  assert.equal((await login.take({client: "c", account: "ben"})).allowed, true, "ein anderes Konto ist nicht betroffen");
});

test("the bucket store forgets the least recently used key beyond its limit", async () => {
  const store = new InMemoryBucketStateStore(2);
  const bucket = new TokenBucketRateLimiter(store, {current: async () => ({capacity: 1, refillPerSecond: 1 / 3600})});
  await bucket.take("a");
  await bucket.take("b");
  await bucket.take("c");
  assert.equal((await bucket.take("a")).allowed, true, "„a“ wurde verdrängt und beginnt mit vollem Eimer");
  assert.equal((await bucket.take("c")).allowed, false);
});
