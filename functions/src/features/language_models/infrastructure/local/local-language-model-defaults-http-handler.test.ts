import assert from "node:assert/strict";
import test from "node:test";
import {LocalLanguageModelDefaultsHttpHandler} from "./local-language-model-defaults-http-handler.js";
import {type LocalRuntimeRequest} from "../../../../shared/local/local-runtime-http-server.js";
import {
  emptyLanguageModelDefaults,
  type LanguageModelDefaults,
} from "../../domain/entities/language-model-defaults.js";
import {type LanguageModelDefaultsStore} from "../../domain/repositories/language-model-defaults-store.js";

class FakeDefaultsStore implements LanguageModelDefaultsStore {
  saved: {teamId: string; defaults: LanguageModelDefaults} | null = null;

  constructor(private current: LanguageModelDefaults = emptyLanguageModelDefaults) {}

  async loadDefaults(): Promise<LanguageModelDefaults> {
    return this.current;
  }

  async saveDefaults(teamId: string, defaults: LanguageModelDefaults): Promise<void> {
    this.saved = {teamId, defaults};
    this.current = defaults;
  }
}

class FakeNotifier {
  published: string[] = [];
  publish(channel: string): void {
    this.published.push(channel);
  }
}

function request(method: string, body: unknown = {}): LocalRuntimeRequest {
  return {method, url: "/v1/language-model-defaults", body} as LocalRuntimeRequest;
}

test("liefert die gespeicherten Vorgaben", async () => {
  const store = new FakeDefaultsStore({blockModelId: "model-1", assistantModelId: null});
  const handler = new LocalLanguageModelDefaultsHttpHandler(store, "team-1", new FakeNotifier() as never);

  const response = await handler.handle(request("GET"));

  assert.equal(response?.statusCode, 200);
  assert.deepEqual(response?.body, {blockModelId: "model-1", assistantModelId: null});
});

test("speichert neue Vorgaben und benachrichtigt Echtzeit-Abonnenten", async () => {
  const store = new FakeDefaultsStore();
  const notifier = new FakeNotifier();
  const handler = new LocalLanguageModelDefaultsHttpHandler(store, "team-1", notifier as never);

  const response = await handler.handle(
    request("PUT", {blockModelId: "model-1", assistantModelId: "model-2"}),
  );

  assert.equal(response?.statusCode, 200);
  assert.deepEqual(store.saved, {
    teamId: "team-1",
    defaults: {blockModelId: "model-1", assistantModelId: "model-2"},
  });
  assert.deepEqual(notifier.published, ["language-model-defaults"]);
});

test("behandelt ein fehlendes Feld als kein Vorgabemodell", async () => {
  const store = new FakeDefaultsStore();
  const handler = new LocalLanguageModelDefaultsHttpHandler(store, "team-1", new FakeNotifier() as never);

  await handler.handle(request("PUT", {blockModelId: "model-1"}));

  assert.deepEqual(store.saved?.defaults, {blockModelId: "model-1", assistantModelId: null});
});

test("weist einen ungültigen Vorgabewert zurück", async () => {
  const handler = new LocalLanguageModelDefaultsHttpHandler(
    new FakeDefaultsStore(), "team-1", new FakeNotifier() as never,
  );

  const response = await handler.handle(request("PUT", {blockModelId: 42}));

  assert.equal(response?.statusCode, 400);
});

test("lässt unbeteiligte Pfade für andere Handler übrig", async () => {
  const handler = new LocalLanguageModelDefaultsHttpHandler(
    new FakeDefaultsStore(), "team-1", new FakeNotifier() as never,
  );

  const response = await handler.handle(
    {method: "GET", url: "/v1/language-models", body: {}} as LocalRuntimeRequest,
  );

  assert.equal(response, null);
});
