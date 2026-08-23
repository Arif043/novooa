import {defineString} from "firebase-functions/params";
import {type ModelInference} from "../../domain/repositories/model-inference.js";
import {GoogleIdTokenJsonHttpClient} from "./authenticated-json-http-client.js";
import {CloudRunModelInference} from "./cloud-run-model-inference.js";

export const modelInferenceServiceUrl = defineString("MODEL_INFERENCE_SERVICE_URL");

export function cloudRunModelInference(): ModelInference {
  return new CloudRunModelInference(
    () => modelInferenceServiceUrl.value(),
    new GoogleIdTokenJsonHttpClient(),
  );
}
