import {Type} from "@fastify/type-provider-typebox";

/** Einheitliche Fehlerantwort aller Routen. */
export const ErrorResponse = Type.Object({
  error: Type.String(),
  code: Type.Optional(Type.String()),
});

export const StatusResponse = Type.Object({status: Type.String()});

export const ItemsOf = <T extends Parameters<typeof Type.Array>[0]>(item: T) =>
  Type.Object({items: Type.Array(item)});

export const NonEmptyString = (options: {maxLength?: number} = {}) =>
  Type.String({minLength: 1, ...options});

/** Frei strukturierte JSON-Objekte (z. B. Aufgaben-Graph, Datensätze). */
export const JsonObject = Type.Record(Type.String(), Type.Unknown());

export const IdParams = <K extends string>(name: K) =>
  Type.Object({[name]: NonEmptyString({maxLength: 200})} as Record<K, ReturnType<typeof NonEmptyString>>);
