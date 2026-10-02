import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {ErrorResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type DiscoveredSkills} from "../../domain/entities/skill-discovery.js";
import {SkillImportError} from "../../domain/entities/skill-import-error.js";
import {type SkillImportOrigin} from "../../domain/entities/skill-import-preview.js";
import {SkillPackageError} from "../../domain/entities/skill-package.js";
import {SkillAlreadyExistsError, SkillNotFoundError, SkillStorageError} from "../../domain/entities/stored-skill.js";
import {type SkillSource} from "../../domain/repositories/skill-source.js";
import {type SkillStore} from "../../domain/repositories/skill-store.js";
import {type CommitSkillImport} from "../../domain/usecases/commit-skill-import.js";
import {type PreviewSkillImport} from "../../domain/usecases/preview-skill-import.js";
import {type DeleteSkill, type ListSkills} from "../../domain/usecases/skill-library.js";
import {type ZipSkillReference} from "../archive/zip-skill-source.js";
import {type FolderSkillReference} from "../files/folder-skill-source.js";
import {type GitHubSkillReference} from "../github/github-skill-source.js";
import {type SkillsShSkillReference} from "../skills_sh/skills-sh-skill-source.js";

export type SkillRoutesOptions = {
  store: SkillStore;
  list: ListSkills;
  remove: DeleteSkill;
  preview: PreviewSkillImport;
  commit: CommitSkillImport;
  sources: {
    github: SkillSource<GitHubSkillReference>;
    archive: SkillSource<ZipSkillReference>;
    folder: SkillSource<FolderSkillReference>;
    /** Fehlt, wenn kein Zugang zu skills.sh eingerichtet ist. */
    skillsSh?: SkillSource<SkillsShSkillReference>;
  };
  notifier: {publish(topic: string): void};
};

const maximumArchiveBytes = 25 * 1024 * 1024;
const maximumFolderRequestBytes = 16 * 1024 * 1024;
const Skill = Type.Object({
  name: Type.String(), description: Type.String(), license: Type.Optional(Type.String()),
  compatibility: Type.Optional(Type.String()), fileCount: Type.Integer(), warnings: Type.Array(Type.String()),
});
const Candidate = Type.Object({
  name: Type.String(), description: Type.String(), fileCount: Type.Integer(), totalBytes: Type.Integer(),
  warnings: Type.Array(Type.String()), nameTaken: Type.Boolean(),
});
const Preview = Type.Object({
  importId: Type.String(),
  origin: Type.Object({kind: Type.String(), reference: Type.String()}),
  candidates: Type.Array(Candidate),
  rejected: Type.Array(Type.Object({directory: Type.String(), reason: Type.String()})),
});
const failures = {400: ErrorResponse, 404: ErrorResponse, 409: ErrorResponse, 413: ErrorResponse, 415: ErrorResponse, 500: ErrorResponse};
const ImportBody = Type.Object({
  github: Type.Optional(Type.Object({url: Type.String({minLength: 1, maxLength: 500})})),
  skillsSh: Type.Optional(Type.Object({id: Type.String({minLength: 3, maxLength: 300})})),
  folder: Type.Optional(Type.Object({
    name: Type.String({minLength: 1, maxLength: 200}),
    files: Type.Array(Type.Object({path: Type.String({maxLength: 1000}), contentBase64: Type.String()}), {maxItems: 2000}),
  })),
});

export const skillRoutes: FastifyPluginAsyncTypebox<SkillRoutesOptions> = async (app, options) => {
  app.get("/v1/skills", {schema: {response: {200: Type.Object({items: Type.Array(Skill)})}}},
    async () => ({items: await options.list.execute()}));

  app.get("/v1/skills/location", {schema: {response: {200: Type.Object({path: Type.String()})}}},
    async () => ({path: options.store.location}));

  app.delete("/v1/skills/:name", {
    schema: {params: Type.Object({name: Type.String({minLength: 1, maxLength: 255})}), response: {...failures, 200: Type.Object({})}},
  }, async (request, reply) => {
    try {
      await options.remove.execute(request.params.name);
      options.notifier.publish("skills");
      return {};
    } catch (error) {
      return failure(error, reply);
    }
  });

  app.post("/v1/skills/imports", {
    bodyLimit: maximumFolderRequestBytes,
    schema: {body: ImportBody, response: {...failures, 201: Preview}},
  }, async (request, reply) => {
    const {github, folder, skillsSh} = request.body;
    if ([github, folder, skillsSh].filter((source) => source !== undefined).length !== 1) {
      return reply.code(400).send({error: "Gib genau eine Quelle an: github, folder oder skillsSh."});
    }
    return previewOf(reply, async () => {
      if (github !== undefined) return stage(options, {kind: "github", reference: github.url}, await options.sources.github.resolve(github));
      if (skillsSh !== undefined) {
        if (options.sources.skillsSh === undefined) throw new SkillImportError("Der Skill-Katalog ist nicht eingerichtet.");
        return stage(options, {kind: "skillsSh", reference: skillsSh.id}, await options.sources.skillsSh.resolve(skillsSh));
      }
      return stage(options, {kind: "folder", reference: folder!.name}, await options.sources.folder.resolve(folder!));
    });
  });

  app.post("/v1/skills/imports/archive", {
    schema: {querystring: Type.Object({name: Type.Optional(Type.String({maxLength: 255}))}), response: {...failures, 201: Preview}},
  }, async (request, reply) => {
    if (request.headers["content-type"]?.split(";", 1)[0] !== "application/zip") {
      return reply.code(415).send({error: "Der Import erwartet eine ZIP-Datei (application/zip)."});
    }
    return previewOf(reply, async () => {
      const fileName = request.query.name?.trim() || "skill.zip";
      const bytes = await readBounded(request.raw);
      return stage(options, {kind: "archive", reference: fileName}, await options.sources.archive.resolve({bytes, fileName}));
    });
  });

  app.post("/v1/skills/imports/:importId/commit", {
    schema: {
      params: Type.Object({importId: Type.String({minLength: 1, maxLength: 100})}),
      body: Type.Object({names: Type.Array(Type.String({maxLength: 100}), {minItems: 1, maxItems: 200})}),
      response: {...failures, 201: Type.Object({items: Type.Array(Skill)})},
    },
  }, async (request, reply) => {
    try {
      const items = await options.commit.execute(request.params.importId, request.body.names);
      options.notifier.publish("skills");
      request.workspace.logger.info("skills.imported", {teamId: request.workspace.teamId, count: items.length});
      return reply.code(201).send({items});
    } catch (error) {
      return failure(error, reply);
    }
  });
};

async function stage(options: SkillRoutesOptions, origin: SkillImportOrigin, discovered: DiscoveredSkills) {
  return options.preview.execute(origin, discovered);
}

async function previewOf(reply: FastifyReply, run: () => Promise<unknown>): Promise<FastifyReply> {
  try {
    return reply.code(201).send(await run());
  } catch (error) {
    return failure(error, reply);
  }
}

async function readBounded(stream: AsyncIterable<Uint8Array>): Promise<Uint8Array> {
  const chunks: Uint8Array[] = [];
  let size = 0;
  for await (const chunk of stream) {
    size += chunk.length;
    if (size > maximumArchiveBytes) throw new SkillImportError(`Das Archiv ist zu groß (höchstens ${maximumArchiveBytes / (1024 * 1024)} MB).`);
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

function failure(error: unknown, reply: FastifyReply): FastifyReply {
  if (error instanceof SkillNotFoundError) return reply.code(404).send({error: error.message});
  if (error instanceof SkillAlreadyExistsError) return reply.code(409).send({error: error.message});
  if (error instanceof SkillStorageError) return reply.code(500).send({error: error.message});
  if (error instanceof SkillImportError || error instanceof SkillPackageError) return reply.code(400).send({error: error.message});
  throw error;
}
