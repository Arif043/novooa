import {defineString} from "firebase-functions/params";
import {type ModelInference} from "../../domain/repositories/model-inference.js";
import {GoogleIdTokenJsonHttpClient} from "./authenticated-json-http-client.js";
import {CloudRunModelInference} from "./cloud-run-model-inference.js";
import {FetchLocalJsonHttpClient, LocalHttpModelInference} from "../local/local-http-model-inference.js";

export const modelInferenceServiceUrl = defineString("MODEL_INFERENCE_SERVICE_URL");

export function modelInference(): ModelInference {
  if (process.env.FUNCTIONS_EMULATOR === "true" && isLocalServiceUrl(modelInferenceServiceUrl.value())) {
    return new LocalHttpModelInference(
      () => modelInferenceServiceUrl.value(),
      new FetchLocalJsonHttpClient(),
    );
  }
  return new CloudRunModelInference(
    () => modelInferenceServiceUrl.value(),
    new GoogleIdTokenJsonHttpClient(),
  );
}

function isLocalServiceUrl(value: string): boolean {
  try {
    return new URL(value).protocol === "http:";
  } catch {
    return false;
  }
}
