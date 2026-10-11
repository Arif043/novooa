import {HeadObjectCommand, S3Client} from "@aws-sdk/client-s3";
import {Upload} from "@aws-sdk/lib-storage";
import {Readable} from "node:stream";
import {type ModelObjectMetadata, type ModelObjectStore} from "./model-object-store.js";

export type S3ModelStoreConfiguration = {
  endpoint: string;
  region: string;
  bucket: string;
  accessKeyId: string;
  secretAccessKey: string;
};

/** S3-kompatibler Speicher (Hetzner Object Storage). Große Dateien gehen per Multipart-Upload als Datenstrom. */
export class S3ModelObjectStore implements ModelObjectStore {
  private readonly client: S3Client;

  constructor(private readonly configuration: S3ModelStoreConfiguration) {
    this.client = new S3Client({
      endpoint: configuration.endpoint,
      region: configuration.region,
      credentials: {accessKeyId: configuration.accessKeyId, secretAccessKey: configuration.secretAccessKey},
      // S3-kompatible Anbieter unterstützen die neueren Standard-Prüfsummen des SDK nicht überall.
      requestChecksumCalculation: "WHEN_REQUIRED",
      responseChecksumValidation: "WHEN_REQUIRED",
    });
  }

  async storedSha256(key: string): Promise<string | null> {
    try {
      const head = await this.client.send(new HeadObjectCommand({Bucket: this.configuration.bucket, Key: key}));
      return head.Metadata?.sha256 ?? "";
    } catch (error) {
      if (isNotFound(error)) return null;
      throw error;
    }
  }

  async put(key: string, content: AsyncIterable<Uint8Array>, metadata: ModelObjectMetadata): Promise<void> {
    await new Upload({
      client: this.client,
      params: {
        Bucket: this.configuration.bucket, Key: key, Body: Readable.from(content),
        ContentType: metadata.contentType, ContentLength: metadata.sizeBytes, Metadata: {sha256: metadata.sha256},
      },
    }).done();
  }
}

export function s3ModelStoreConfigurationFromEnvironment(environment = process.env): S3ModelStoreConfiguration {
  return {
    endpoint: required(environment, "MODEL_STORE_S3_ENDPOINT"),
    region: environment.MODEL_STORE_S3_REGION?.trim() || "eu-central",
    bucket: required(environment, "MODEL_STORE_S3_BUCKET"),
    accessKeyId: required(environment, "MODEL_STORE_S3_ACCESS_KEY_ID"),
    secretAccessKey: required(environment, "MODEL_STORE_S3_SECRET_ACCESS_KEY"),
  };
}

function required(environment: NodeJS.ProcessEnv, name: string): string {
  const value = environment[name]?.trim();
  if (!value) throw new Error(`${name} fehlt.`);
  return value;
}

function isNotFound(error: unknown): boolean {
  if (typeof error !== "object" || error === null) return false;
  const status = (error as {$metadata?: {httpStatusCode?: number}}).$metadata?.httpStatusCode;
  return status === 404 || (error as {name?: string}).name === "NotFound";
}
