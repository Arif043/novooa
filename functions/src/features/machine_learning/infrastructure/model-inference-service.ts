import {createModelInferenceHttpServer} from "./model-inference-http-server.js";
import {createModelInferenceService} from "./model-inference-service-composition.js";

const port = portFromEnvironment();
const server = createModelInferenceHttpServer(createModelInferenceService());

server.listen(port, "0.0.0.0", () => {
  console.info(JSON.stringify({event: "model_inference_service_started", port}));
});

function portFromEnvironment(): number {
  const value = Number(process.env.PORT ?? "8080");
  if (!Number.isSafeInteger(value) || value < 1 || value > 65535) {
    throw new Error("Der PORT für den Inferenzdienst ist ungültig.");
  }
  return value;
}
