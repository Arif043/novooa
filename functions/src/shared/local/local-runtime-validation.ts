import Ajv, {type Options} from "ajv";
import addFormats from "ajv-formats";
import {type FastifyInstance} from "fastify";

/** Wie Fastifys Standard-Ajv, nur pro Request-Teil unterschiedlich streng. */
const baseOptions: Options = {useDefaults: true, removeAdditional: true, allErrors: false};

/**
 * Pfad-, Query- und Header-Werte kommen immer als Text an und werden in den
 * Schema-Typ umgewandelt (`"5"` → `5`). JSON-Bodies sind bereits typisiert —
 * dort wäre eine stille Umwandlung (`42` → `"42"`) ein verdeckter
 * Client-Fehler, deshalb ohne Coercion.
 */
const compilers = {
  body: withFormats(new Ajv({...baseOptions, coerceTypes: false})),
  coercing: withFormats(new Ajv({...baseOptions, coerceTypes: "array"})),
};

export function configureValidation(http: FastifyInstance): void {
  http.setValidatorCompiler(({schema, httpPart}) => {
    const compiler = httpPart === "body" ? compilers.body : compilers.coercing;
    return compiler.compile(schema);
  });
}

function withFormats(ajv: Ajv): Ajv {
  addFormats.default(ajv);
  return ajv;
}
