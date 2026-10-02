/**
 * Name eines Skills nach agentskills.io: 1–64 Zeichen, kleine Buchstaben und Ziffern,
 * Bindestriche nur zwischen Wörtern. Er ist zugleich der Ordnername, unter dem die
 * Genkit-Skill-Middleware den Skill dem Modell anbietet.
 */
export class SkillName {
  static readonly maximumLength = 64;
  private static readonly pattern = /^[\p{Ll}\p{Nd}]+(?:-[\p{Ll}\p{Nd}]+)*$/u;

  private constructor(readonly value: string) {}

  /** `null`, wenn der Text den Standard nicht erfüllt. */
  static parse(text: string): SkillName | null {
    const candidate = text.trim();
    if (candidate.length === 0 || candidate.length > SkillName.maximumLength) return null;
    return SkillName.pattern.test(candidate) ? new SkillName(candidate) : null;
  }

  /** Macht aus beliebigem Text (Ordnername, Titel) einen gültigen Namen; `null`, wenn nichts übrig bleibt. */
  static slugFrom(text: string): SkillName | null {
    const slug = text
      .normalize("NFKD")
      .replace(/\p{M}+/gu, "")
      .toLowerCase()
      .replace(/[^\p{Ll}\p{Nd}]+/gu, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, SkillName.maximumLength)
      .replace(/-+$/g, "");
    return SkillName.parse(slug);
  }

  /** Ein freier Name für `base`: hängt `-2`, `-3` … an, bis er nicht in `taken` vorkommt. */
  static uniqueFor(base: SkillName, taken: ReadonlySet<string>): SkillName {
    if (!taken.has(base.value)) return base;
    for (let counter = 2; ; counter++) {
      const suffix = `-${counter}`;
      const trimmed = base.value.slice(0, SkillName.maximumLength - suffix.length).replace(/-+$/g, "");
      const next = SkillName.parse(`${trimmed}${suffix}`);
      if (next !== null && !taken.has(next.value)) return next;
    }
  }
}
