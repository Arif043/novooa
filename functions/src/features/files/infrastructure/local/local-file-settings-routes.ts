import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FileSettingsStore} from "../../domain/repositories/file-settings-store.js";

export type FileSettingsRoutesOptions = {
  store: FileSettingsStore;
  notifier: {publish(topic: string): void};
};

const FileSettingsSchema = Type.Object({versionLimit: Type.Integer({minimum: 1, maximum: 1000})});

export const fileSettingsRoutes: FastifyPluginAsyncTypebox<FileSettingsRoutesOptions> = async (app, {store, notifier}) => {
  app.get("/v1/file-settings", {schema: {response: {200: FileSettingsSchema}}},
    async (request) => ({versionLimit: await store.loadVersionLimit(request.workspace.teamId)}));

  app.put("/v1/file-settings", {schema: {body: FileSettingsSchema, response: {200: FileSettingsSchema}}},
    async (request) => {
      await store.saveVersionLimit(request.workspace.teamId, request.body.versionLimit);
      notifier.publish("file-settings");
      return request.body;
    });
};
