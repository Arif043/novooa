import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {PluginError} from "../../domain/entities/plugin-state.js";
import {type ListPlugins, type SetPluginEnabled} from "../../domain/usecases/plugin-usecases.js";

export type PluginRoutesOptions = {
  list: ListPlugins;
  setEnabled: SetPluginEnabled;
  notifier: {publish(topic: string): void};
};

const PluginStateDto = Type.Object({
  id: Type.String(), enabled: Type.Boolean(), enabledAt: Type.Union([Type.String(), Type.Null()]),
});
const ErrorDto = Type.Object({error: Type.String(), code: Type.Optional(Type.String())});

/** Lesen dürfen alle (die Palette braucht es), schalten nur Admins (Rollen-Policy, Schreibzugriffe). */
export const pluginRoutes: FastifyPluginAsyncTypebox<PluginRoutesOptions> = async (app, {list, setEnabled, notifier}) => {
  app.get("/v1/plugins", {schema: {response: {200: Type.Object({items: Type.Array(PluginStateDto)})}}},
    async (request) => ({items: await list.execute(request.workspace.teamId)}));

  app.put("/v1/plugins/:id", {schema: {
    params: Type.Object({id: Type.String({maxLength: 100})}),
    body: Type.Object({enabled: Type.Boolean()}, {additionalProperties: false}),
    response: {200: PluginStateDto, 404: ErrorDto},
  }}, async (request, reply) => {
    try {
      const plugin = await setEnabled.execute({
        teamId: request.workspace.teamId, pluginId: request.params.id, enabled: request.body.enabled, uid: request.actor.uid,
      });
      notifier.publish("plugins");
      return plugin;
    } catch (error) {
      if (error instanceof PluginError) return reply.code(404).send({error: error.message, code: error.code});
      throw error;
    }
  });
};
