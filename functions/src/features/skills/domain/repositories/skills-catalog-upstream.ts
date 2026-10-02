import {type SkillRelayRequest} from "../entities/skill-relay-request.js";

export type SkillsCatalogResponse = {
  status: number;
  body: string;
  /** Nur die Header, die die Runtime braucht: Content-Type, Cache-Control, Retry-After, X-RateLimit-*. */
  headers: Record<string, string>;
};

/** Der Weg zum Katalog hinter dem Relay (der signierende Vercel-Proxy). */
export interface SkillsCatalogUpstream {
  get(request: SkillRelayRequest): Promise<SkillsCatalogResponse>;
}
