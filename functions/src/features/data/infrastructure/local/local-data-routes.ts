import {type FastifyPluginAsyncTypebox} from "@fastify/type-provider-typebox";
import {dataCollectionRoutes} from "./local-data-collection-routes.js";
import {dataDocumentRoutes} from "./local-data-document-routes.js";
import {type DataRoutesOptions} from "./local-data-route-schemas.js";
import {dataTransferRoutes} from "./local-data-transfer-routes.js";

export type {DataRoutesOptions} from "./local-data-route-schemas.js";

/** Alle Routen der Datenbank; die Transfer-Routen haben eigenen Body-Parser und Fehler-Handler. */
export const dataRoutes: FastifyPluginAsyncTypebox<DataRoutesOptions> = async (app, options) => {
  await app.register(dataCollectionRoutes, options);
  await app.register(dataDocumentRoutes, options);
  await app.register(dataTransferRoutes, options);
};
