import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type GoogleAccountsModule} from "./google-accounts-module.js";

export type GoogleAccountRoutesOptions = {
  signedLicense: () => SignedRuntimeLicense | null;
  module: Pick<GoogleAccountsModule, "relay" | "cache">;
};

const GoogleAccount = Type.Object({
  id: Type.String(), email: Type.String(),
  status: Type.Union([Type.Literal("active"), Type.Literal("reauthorizationRequired")]),
  sharedItems: Type.Array(Type.Object({id: Type.String(), name: Type.String(), mimeType: Type.String()})),
});

/** Google-Konten der Runtime; Quelle ist das Relay, die Liste kommt aus dem Cache bis zum nächsten Wake-up. */
export const googleAccountRoutes: FastifyPluginAsyncTypebox<GoogleAccountRoutesOptions> = async (app, {signedLicense, module}) => {
  const activeLicense = (): SignedRuntimeLicense => {
    const license = signedLicense();
    if (license === null) throw new Error("Die lokale Runtime hat keine aktive Lizenz.");
    return license;
  };

  app.get("/v1/google-accounts", {
    schema: {response: {200: ItemsOf(GoogleAccount)}},
  }, async () => {
    const license = activeLicense();
    return {items: await module.cache.list(license, () => module.relay.listAccounts(license))};
  });

  app.post("/v1/google-accounts/authorization", {
    schema: {
      body: Type.Object({loginHint: Type.Optional(Type.String({minLength: 3, maxLength: 320}))}),
      response: {200: Type.Object({authorizationUrl: Type.String()})},
    },
  }, async (request) => module.relay.beginAuthorization(activeLicense(), request.body.loginHint));
};
