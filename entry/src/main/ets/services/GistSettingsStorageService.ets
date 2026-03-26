import fs from '@ohos.file.fs';
import type { GistSyncSettings } from '../model/GistSyncSettings';
import { canAccessPath, writeTextFile } from './LocalFsService';

const DEFAULT_FILE_NAME: string = 'BookmarkHub';

/** 空配置（首次打开同步页时使用） */
export function defaultGistSyncSettings(): GistSyncSettings {
  return {
    githubToken: '',
    gistId: '',
    gistFileName: DEFAULT_FILE_NAME,
    autoUploadAfterEdit: false,
    autoPullOnTabFocus: false
  };
}

export function saveGistSyncSettings(cachePath: string, settings: GistSyncSettings): void {
  writeTextFile(cachePath, JSON.stringify(settings));
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
    const rec = parsed as Record<string, string | undefined>;
    const token: string = rec['githubToken'] ?? '';
    const id: string = rec['gistId'] ?? '';
    let fileName: string = rec['gistFileName'] ?? DEFAULT_FILE_NAME;
    if (fileName.trim().length === 0) {
      fileName = DEFAULT_FILE_NAME;
    }
    const autoUpVal: Object | undefined = rec['autoUploadAfterEdit'];
    const autoPullVal: Object | undefined = rec['autoPullOnTabFocus'];
    const autoUploadAfterEdit: boolean = autoUpVal === true;
    const autoPullOnTabFocus: boolean = autoPullVal === true;
    return {
      githubToken: token,
      gistId: id,
      gistFileName: fileName,
      autoUploadAfterEdit: autoUploadAfterEdit,
      autoPullOnTabFocus: autoPullOnTabFocus
    };
  } catch (_e) {
    return defaultGistSyncSettings();
  }
}
