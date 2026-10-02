import {type SkillPackage} from "./skill-package.js";

export type SkillImportOrigin = {
  kind: "github" | "archive" | "folder" | "skillsSh";
  /** Adresse, Dateiname oder Katalog-ID — nur zur Anzeige. */
  reference: string;
};

export type SkillImportCandidate = {
  name: string;
  description: string;
  fileCount: number;
  totalBytes: number;
  warnings: string[];
  /** Der Name ist schon vergeben; beim Übernehmen wird `-2`, `-3` … angehängt. */
  nameTaken: boolean;
};

export type SkillImportRejection = {directory: string; reason: string};

export type SkillImportPreview = {
  importId: string;
  origin: SkillImportOrigin;
  candidates: SkillImportCandidate[];
  rejected: SkillImportRejection[];
};

export type StagedSkillImport = {
  origin: SkillImportOrigin;
  packages: SkillPackage[];
  rejected: SkillImportRejection[];
};
