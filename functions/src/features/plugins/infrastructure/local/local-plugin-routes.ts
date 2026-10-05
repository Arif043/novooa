import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {ErrorResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {SkillImportError} from "../../../skills/domain/entities/skill-import-error.js";
import {readZipFiles, withoutCommonRoot} from "../../../skills/infrastructure/archive/zip-reader.js";
import {PluginPackageError} from "../../domain/entities/plugin-package-error.js";
import {PluginNotFoundError, PluginStorageError} from "../../domain/entities/stored-plugin.js";
import {type CommitPluginInstall, type PreviewPluginInstall} from "../../domain/usecases/plugin-install.js";
import {type ListPlugins, type UninstallPlugin} from "../../domain/usecases/plugin-library.js";
import {type GetPluginSettings, type SetPluginSettings} from "../../domain/usecases/plugin-settings.js";

export type PluginRoutesOptions = {
  list: ListPlugins;
  uninstall: UninstallPlugin;
  preview: PreviewPluginInstall;
  commit: CommitPluginInstall;
  getSettings: GetPluginSettings;
  setSettings: SetPluginSettings;
  notifier: {publish(topic: string): void};
};

const maximumArchiveBytes = 15 * 1024 * 1024;
const failures = {400: ErrorResponse, 404: ErrorResponse, 413: ErrorResponse, 415: ErrorResponse, 500: ErrorResponse};
// Das Manifest wird im Domain-Teil geprüft; die Route reicht es unverändert an den Client durch.
const Json = Type.Unsafe<Record<string, unknown>>(Type.Object({}, {additionalProperties: true}));
const Plugin = Type.Object({id: Type.String(), version: Type.String(), name: Type.String(), description: Type.String(), manifest: Json});
const SettingValues = Type.Record(Type.String({maxLength: 40}), Type.Union([Type.String({maxLength: 5000}), Type.Number(), Type.Boolean()]), {maxProperties: 100});

export const pluginRoutes: FastifyPluginAsyncTypebox<PluginRoutesOptions> = async (app, options) => {
  app.get("/v1/plugins", {schema: {response: {200: Type.Object({items: Type.Array(Plugin)})}}},
    async () => ({items: await options.list.execute()}));

  app.delete("/v1/plugins/:id", {
    schema: {params: Type.Object({id: Type.String({minLength: 1, maxLength: 60})}), response: {...failures, 200: Type.Object({})}},
  }, async (request, reply) => {
    try {
      await options.uninstall.execute(request.params.id);
      options.notifier.publish("plugins");
      return {};
    } catch (error) {
      return failure(error, reply);
    }
  });

  app.post("/v1/plugins/installs/archive", {
    schema: {
      response: {
        ...failures,
        201: Type.Object({installId: Type.String(), manifest: Json, installedVersion: Type.Optional(Type.String())}),
      },
    },
  }, async (request, reply) => {
    if (request.headers["content-type"]?.split(";", 1)[0] !== "application/zip") {
      return reply.code(415).send({error: "Die Installation erwartet eine ZIP-Datei (application/zip)."});
    }
    try {
      const bytes = await readBounded(request.raw);
      const files = withoutCommonRoot(readZipFiles(bytes)).files;
      return reply.code(201).send(await options.preview.execute(files));
    } catch (error) {
      return failure(error, reply);
    }
  });

  app.post("/v1/plugins/installs/:installId/commit", {
    schema: {params: Type.Object({installId: Type.String({minLength: 1, maxLength: 100})}), response: {...failures, 201: Plugin}},
  }, async (request, reply) => {
    try {
      const plugin = await options.commit.execute(request.params.installId);
      options.notifier.publish("plugins");
      request.workspace.logger.info("plugins.installed", {teamId: request.workspace.teamId, pluginId: plugin.id, version: plugin.version});
      return reply.code(201).send(plugin);
    } catch (error) {
      return failure(error, reply);
    }
  });

  app.get("/v1/plugins/:id/settings", {
    schema: {
      params: Type.Object({id: Type.String({minLength: 1, maxLength: 60})}),
      response: {...failures, 200: Type.Object({values: SettingValues, secretsSet: Type.Array(Type.String())})},
    },
  }, async (request, reply) => {
    try {
      return await options.getSettings.execute(request.params.id);
    } catch (error) {
      return failure(error, reply);
    }
  });

  app.put("/v1/plugins/:id/settings", {
    schema: {
      params: Type.Object({id: Type.String({minLength: 1, maxLength: 60})}),
      body: Type.Object({values: SettingValues}),
      response: {...failures, 200: Type.Object({})},
    },
  }, async (request, reply) => {
    try {
      await options.setSettings.execute(request.params.id, request.body.values);
      options.notifier.publish("plugins");
      return {};
    } catch (error) {
      return failure(error, reply);
    }
  });
};

async function readBounded(stream: AsyncIterable<Uint8Array>): Promise<Uint8Array> {
  const chunks: Uint8Array[] = [];
  let size = 0;
  for await (const chunk of stream) {
    size += chunk.length;
    if (size > maximumArchiveBytes) throw new PluginPackageError(`Das Plugin ist zu groß (höchstens ${maximumArchiveBytes / (1024 * 1024)} MB).`);
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

function failure(error: unknown, reply: FastifyReply): FastifyReply {
  if (error instanceof PluginNotFoundError) return reply.code(404).send({error: error.message});
  if (error instanceof PluginStorageError) return reply.code(500).send({error: error.message});
  if (error instanceof PluginPackageError || error instanceof SkillImportError) return reply.code(400).send({error: error.message});
  throw error;
}
