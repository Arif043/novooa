import {getRemoteConfig, type ServerTemplate} from "firebase-admin/remote-config";
import {defaultBucketConfig, normalizedBucketConfig, type BucketConfig} from "../../../../shared/rate_limiting/domain/entities/token-bucket.js";
import {type BucketSettings} from "../../../../shared/rate_limiting/domain/repositories/bucket-ports.js";
import {logException} from "../../../../shared/logging/logger.js";

export const capacityKey = "skills_relay_bucket_capacity";
export const refillPerSecondKey = "skills_relay_bucket_refill_per_second";

const refreshMilliseconds = 5 * 60 * 1000;
const retryAfterFailureMilliseconds = 30 * 1000;

/**
 * Liest Kapazität und Nachfüllrate aus Firebase Remote Config (Server-Template). Änderungen in der Console wirken
 * nach spätestens fünf Minuten, ohne Deploy. Bei Fehlern (Remote Config nicht erreichbar) gilt der zuletzt bekannte
 * Stand, zuerst die Standardwerte; nach 30 s wird erneut versucht.
 */
export class RemoteConfigBucketSettings implements BucketSettings {
  private template: ServerTemplate | undefined;
  private config: BucketConfig = defaultBucketConfig;
  private validUntil = 0;
  private refreshing: Promise<void> | undefined;

  constructor(
    private readonly createTemplate: () => ServerTemplate = () => getRemoteConfig().initServerTemplate({
      defaultConfig: {[capacityKey]: defaultBucketConfig.capacity, [refillPerSecondKey]: defaultBucketConfig.refillPerSecond},
    }),
    private readonly now: () => number = Date.now,
  ) {}

  async current(): Promise<BucketConfig> {
    if (this.now() >= this.validUntil) await (this.refreshing ??= this.refresh().finally(() => { this.refreshing = undefined; }));
    return this.config;
  }

  private async refresh(): Promise<void> {
    try {
      this.template ??= this.createTemplate();
      await this.template.load();
      const evaluated = this.template.evaluate();
      this.config = normalizedBucketConfig({
        capacity: evaluated.getNumber(capacityKey),
        refillPerSecond: evaluated.getNumber(refillPerSecondKey),
      });
      this.validUntil = this.now() + refreshMilliseconds;
    } catch (error) {
      logException("skills_relay.remote_config_failed", error);
      this.validUntil = this.now() + retryAfterFailureMilliseconds;
    }
  }
}
