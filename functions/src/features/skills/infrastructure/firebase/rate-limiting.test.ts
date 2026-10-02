import assert from "node:assert/strict";
import test from "node:test";
import {type ServerTemplate} from "firebase-admin/remote-config";
import {type BucketState} from "../../domain/entities/token-bucket.js";
import {type BucketSettings, type BucketStateStore} from "../../domain/repositories/bucket-ports.js";
import {TokenBucketRateLimiter} from "../../domain/usecases/token-bucket-rate-limiter.js";
import {capacityKey, refillPerSecondKey, RemoteConfigBucketSettings} from "./remote-config-bucket-settings.js";

class MemoryStore implements BucketStateStore {
  readonly states = new Map<string, BucketState>();
  writes = 0;

  async transact<Result>(key: string, mutate: (state: BucketState | undefined) => {next?: BucketState; result: Result}): Promise<Result> {
    const {next, result} = mutate(this.states.get(key));
    if (next) {
      this.states.set(key, next);
      this.writes++;
    }
    return result;
  }
}

const settings = (capacity: number, refillPerSecond: number): BucketSettings => ({current: async () => ({capacity, refillPerSecond})});

test("each license has its own bucket", async () => {
  const limiter = new TokenBucketRateLimiter(new MemoryStore(), settings(2, 0.5), () => 0);

  assert.equal((await limiter.take("a")).allowed, true);
  assert.equal((await limiter.take("a")).allowed, true);
  assert.equal((await limiter.take("a")).allowed, false);
  assert.equal((await limiter.take("b")).allowed, true, "another license is unaffected");
});

test("the bucket refills over time and rejected attempts neither consume nor write", async () => {
  let now = 0;
  const store = new MemoryStore();
  const limiter = new TokenBucketRateLimiter(store, settings(1, 0.5), () => now);

  await limiter.take("a");
  const writesAfterFirst = store.writes;
  const rejected = await limiter.take("a");
  now = 1_000;
  const stillRejected = await limiter.take("a");
  now = 2_000;
  const refilled = await limiter.take("a");

  assert.deepEqual(rejected, {allowed: false, retryAfterSeconds: 2});
  assert.deepEqual(stillRejected, {allowed: false, retryAfterSeconds: 1});
  assert.equal(refilled.allowed, true);
  assert.equal(store.writes, writesAfterFirst + 1, "only the allowed call wrote");
});

test("changed settings apply to the next request", async () => {
  let capacity = 1;
  const limiter = new TokenBucketRateLimiter(new MemoryStore(), {current: async () => ({capacity, refillPerSecond: 1})}, () => 0);

  await limiter.take("a");
  assert.equal((await limiter.take("a")).allowed, false);
  capacity = 5;
  assert.equal((await limiter.take("a")).allowed, false, "tokens only come with time, not with the new capacity");
});

function templateWith(values: () => Record<string, number>, loads: {count: number}, failLoad = () => false): ServerTemplate {
  return {
    load: async () => { loads.count++; if (failLoad()) throw new Error("offline"); },
    evaluate: () => ({getNumber: (key: string) => values()[key] ?? 0}),
    set: () => undefined,
    toJSON: () => ({}),
  } as unknown as ServerTemplate;
}

test("Remote Config values are read, cached for five minutes and then refreshed", async () => {
  let now = 0;
  let values = {[capacityKey]: 40, [refillPerSecondKey]: 2};
  const loads = {count: 0};
  const remote = new RemoteConfigBucketSettings(() => templateWith(() => values, loads), () => now);

  assert.deepEqual(await remote.current(), {capacity: 40, refillPerSecond: 2});
  values = {[capacityKey]: 10, [refillPerSecondKey]: 1};
  now = 299_999;
  assert.deepEqual(await remote.current(), {capacity: 40, refillPerSecond: 2});
  now = 300_000;
  assert.deepEqual(await remote.current(), {capacity: 10, refillPerSecond: 1});
  assert.equal(loads.count, 2);
});

test("missing or invalid Remote Config values fall back to the defaults per value", async () => {
  const remote = new RemoteConfigBucketSettings(() => templateWith(() => ({[capacityKey]: 0, [refillPerSecondKey]: 3}), {count: 0}), () => 0);

  assert.deepEqual(await remote.current(), {capacity: 20, refillPerSecond: 3});
});

test("when Remote Config fails the last known values stay, and it retries after 30 seconds", async () => {
  let now = 0;
  let fail = false;
  const loads = {count: 0};
  const remote = new RemoteConfigBucketSettings(
    () => templateWith(() => ({[capacityKey]: 7, [refillPerSecondKey]: 1}), loads, () => fail), () => now,
  );

  assert.equal((await remote.current()).capacity, 7);
  fail = true;
  now = 300_000;
  assert.equal((await remote.current()).capacity, 7, "last known value");
  now = 329_999;
  await remote.current();
  assert.equal(loads.count, 2, "no retry within 30 seconds");
  now = 330_000;
  fail = false;
  await remote.current();
  assert.equal(loads.count, 3);
});

test("a failing first load uses the defaults", async () => {
  const remote = new RemoteConfigBucketSettings(() => templateWith(() => ({}), {count: 0}, () => true), () => 0);

  assert.deepEqual(await remote.current(), {capacity: 20, refillPerSecond: 0.5});
});

test("parallel requests share one refresh", async () => {
  const loads = {count: 0};
  const remote = new RemoteConfigBucketSettings(() => templateWith(() => ({[capacityKey]: 9, [refillPerSecondKey]: 1}), loads), () => 0);

  await Promise.all([remote.current(), remote.current(), remote.current()]);

  assert.equal(loads.count, 1);
});
