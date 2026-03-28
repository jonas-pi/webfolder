import fs from '@ohos.file.fs';
import type { GistProviderCredentials, GistSyncSettings } from '../model/GistSyncSettings';
import {
  DEFAULT_GIST_FILE_NAME,
  GIST_PROVIDER_GITHUB,
  GIST_PROVIDER_GITEE,
  defaultGistProviderCredentials
} from '../model/GistSyncSettings';
import { canAccessPath, writeTextFile } from './LocalFsService';

/** 空配置（首次打开同步页时使用） */
export function defaultGistSyncSettings(): GistSyncSettings {
  return {
    gistProvider: GIST_PROVIDER_GITHUB,
    github: defaultGistProviderCredentials(),
    gitee: defaultGistProviderCredentials(),
    autoUploadAfterEdit: false,
    autoPullOnTabFocus: false
  };
}

export function saveGistSyncSettings(cachePath: string, settings: GistSyncSettings): void {
  writeTextFile(cachePath, JSON.stringify(settings));
}

function parseNestedCredential(obj: Object | undefined): GistProviderCredentials | null {
  if (obj === undefined || typeof obj !== 'object') {
    return null;
  }
  const r = obj as Record<string, string | undefined>;
  const t: string = typeof r['gistToken'] === 'string' ? r['gistToken'] : '';
  const id: string = typeof r['gistId'] === 'string' ? r['gistId'] : '';
  let fn: string = typeof r['gistFileName'] === 'string' ? r['gistFileName'] : DEFAULT_GIST_FILE_NAME;
  if (fn.trim().length === 0) {
    fn = DEFAULT_GIST_FILE_NAME;
  }
  return { gistToken: t, gistId: id, gistFileName: fn };
}

export async function loadGistSyncSettings(cachePath: string): Promise<GistSyncSettings> {
  if (!canAccessPath(cachePath)) {
    return defaultGistSyncSettings();
  }
  const content: string = await fs.readText(cachePath);
  if (content.length === 0) {
    return defaultGistSyncSettings();
  }
  try {
    const parsed: object = JSON.parse(content) as object;
    const rec = parsed as Record<string, string | Object | undefined>;
    let provider: string = typeof rec['gistProvider'] === 'string' ? (rec['gistProvider'] as string) : '';
    if (provider !== GIST_PROVIDER_GITEE) {
      provider = GIST_PROVIDER_GITHUB;
    }
    const ghNested: GistProviderCredentials | null = parseNestedCredential(rec['github'] as Object | undefined);
    const giteeNested: GistProviderCredentials | null = parseNestedCredential(rec['gitee'] as Object | undefined);
    if (ghNested !== null && giteeNested !== null) {
      const autoUpVal: Object | undefined = rec['autoUploadAfterEdit'];
      const autoPullVal: Object | undefined = rec['autoPullOnTabFocus'];
      return {
        gistProvider: provider,
        github: ghNested,
        gitee: giteeNested,
        autoUploadAfterEdit: autoUpVal === true,
        autoPullOnTabFocus: autoPullVal === true
      };
    }
    // ── 旧版：单一 gistToken / gistId / gistFileName，按 gistProvider 归入一侧 ──
    const legacyGithubToken: string =
      typeof rec['githubToken'] === 'string' ? (rec['githubToken'] as string) : '';
    const gistTokenNew: string = typeof rec['gistToken'] === 'string' ? (rec['gistToken'] as string) : '';
    const token: string = gistTokenNew.length > 0 ? gistTokenNew : legacyGithubToken;
    const id: string = typeof rec['gistId'] === 'string' ? (rec['gistId'] as string) : '';
    let fileName: string =
      typeof rec['gistFileName'] === 'string' ? (rec['gistFileName'] as string) : DEFAULT_GIST_FILE_NAME;
    if (fileName.trim().length === 0) {
      fileName = DEFAULT_GIST_FILE_NAME;
    }
    const github: GistProviderCredentials = defaultGistProviderCredentials();
    const gitee: GistProviderCredentials = defaultGistProviderCredentials();
    const legacyRow: GistProviderCredentials = { gistToken: token, gistId: id, gistFileName: fileName };
    if (provider === GIST_PROVIDER_GITEE) {
      gitee.gistToken = legacyRow.gistToken;
      gitee.gistId = legacyRow.gistId;
      gitee.gistFileName = legacyRow.gistFileName;
    } else {
      github.gistToken = legacyRow.gistToken;
      github.gistId = legacyRow.gistId;
      github.gistFileName = legacyRow.gistFileName;
    }
    const autoUpVal: Object | undefined = rec['autoUploadAfterEdit'];
    const autoPullVal: Object | undefined = rec['autoPullOnTabFocus'];
    return {
      gistProvider: provider,
      github: github,
      gitee: gitee,
      autoUploadAfterEdit: autoUpVal === true,
      autoPullOnTabFocus: autoPullVal === true
    };
  } catch (_e) {
    return defaultGistSyncSettings();
  }
}
