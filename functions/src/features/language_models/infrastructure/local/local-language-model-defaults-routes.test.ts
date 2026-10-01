import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import assert from "node:assert/strict";
import test from "node:test";
import {languageModelDefaultsRoutes} from "./local-language-model-defaults-routes.js";
import {type TestRequest as LocalRuntimeRequest} from "../../../../shared/local/local-runtime-http-test-support.js";
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

test("liest und speichert die Vorgaben des Teams aus dem Request-Kontext", async () => {
  const store = new FakeDefaultsStore({blockModelId: "first", assistantModelId: null});
  const handler = testingRoutes(languageModelDefaultsRoutes, {store, notifier: new FakeNotifier()}, {teamId: "team-2"});

  await handler.handle(request("PUT", {blockModelId: "model-9"}));

  assert.equal(store.saved?.teamId, "team-2");
});

function request(method: string, body: unknown = {}): LocalRuntimeRequest {
  return {method, url: "/v1/language-model-defaults", body} as LocalRuntimeRequest;
}

test("liefert die gespeicherten Vorgaben", async () => {
  const store = new FakeDefaultsStore({blockModelId: "model-1", assistantModelId: null});
  const handler = testingRoutes(languageModelDefaultsRoutes, {store: store, notifier: new FakeNotifier()});

  const response = await handler.handle(request("GET"));

  assert.equal(response?.statusCode, 200);
  assert.deepEqual(response?.body, {blockModelId: "model-1", assistantModelId: null});
});

test("speichert neue Vorgaben und benachrichtigt Echtzeit-Abonnenten", async () => {
  const store = new FakeDefaultsStore();
  const notifier = new FakeNotifier();
  const handler = testingRoutes(languageModelDefaultsRoutes, {store: store, notifier: notifier});

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
  const handler = testingRoutes(languageModelDefaultsRoutes, {store: store, notifier: new FakeNotifier()});

  await handler.handle(request("PUT", {blockModelId: "model-1"}));

  assert.deepEqual(store.saved?.defaults, {blockModelId: "model-1", assistantModelId: null});
});

test("weist einen ungültigen Vorgabewert zurück", async () => {
  const handler = testingRoutes(languageModelDefaultsRoutes, {store: new FakeDefaultsStore(), notifier: new FakeNotifier()});

  const response = await handler.handle(request("PUT", {blockModelId: 42}));

  assert.equal(response?.statusCode, 400);
});

test("lässt unbeteiligte Pfade für andere Handler übrig", async () => {
  const handler = testingRoutes(languageModelDefaultsRoutes, {store: new FakeDefaultsStore(), notifier: new FakeNotifier()});

  const response = await handler.handle(
    {method: "GET", url: "/v1/language-models", body: {}} as LocalRuntimeRequest,
  );

  assert.equal(response, null);
});
