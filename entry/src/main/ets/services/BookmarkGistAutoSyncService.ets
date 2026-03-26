import type { SyncDataInfo } from '../model/BookmarkSyncTypes';
import { bookmarkPayloadFromParsedJson, flatItemsToSyncData } from '../utils/BookmarkHubSyncConverter';
import { loadBookmarkSyncData, saveBookmarkSyncData } from './BookmarkStorageService';
import { loadGistSyncSettings, defaultGistSyncSettings } from './GistSettingsStorageService';
import { githubFetchGistRaw, extractGistFileText, githubPatchGistFiles } from './GithubGistApi';
import { isBookmarkGistDirty } from './BookmarkGistLocalState';

/** 本地编辑后防抖上传的等待时间（毫秒） */
export const GIST_AUTO_UPLOAD_DEBOUNCE_MS: number = 4500;

function gistSettingsPath(filesDir: string): string {
  return `${filesDir}/gist_sync_settings.json`;
}

function bookmarkCachePath(filesDir: string): string {
  return `${filesDir}/bookmarks_cache.json`;
}

/**
 * 是否已填写可发起请求的三项配置。
 */
function gistCredentialsReady(token: string, gistId: string, fileName: string): boolean {
  return token.trim().length > 0 && gistId.trim().length > 0 && fileName.trim().length > 0;
}

/**
 * 将当前磁盘上的书签快照上传到 Gist（成功后会更新 createDate 并 clear dirty）。
 * 供防抖任务调用；若未开启自动上传或配置不全则立即返回。
 */
export async function runGistAutoUploadFromDisk(filesDir: string): Promise<void> {
  const settings = await loadGistSyncSettings(gistSettingsPath(filesDir));
  if (!settings.autoUploadAfterEdit) {
    return;
  }
  const token: string = settings.githubToken.trim();
  const gid: string = settings.gistId.trim();
  const fn: string = settings.gistFileName.trim().length > 0 ? settings.gistFileName.trim() :
    defaultGistSyncSettings().gistFileName;
  if (!gistCredentialsReady(token, gid, fn)) {
    return;
  }
  const bmPath: string = bookmarkCachePath(filesDir);
  let sync: SyncDataInfo | null = await loadBookmarkSyncData(bmPath);
  if (sync === null) {
    sync = flatItemsToSyncData([]);
  }
  sync.createDate = Date.now();
  sync.browser = 'HarmonyOS/HM';
  const payload: string = JSON.stringify(sync);
  await githubPatchGistFiles(token, gid, fn, payload);
  saveBookmarkSyncData(bmPath, sync);
}

/**
 * 进入收藏夹 Tab 时：若开启自动拉取、配置齐全、且本地无未上传变更，且远端 createDate 更新，则覆盖本地并返回 true。
 */
export async function tryGistAutoPullFromDisk(filesDir: string): Promise<boolean> {
  const settings = await loadGistSyncSettings(gistSettingsPath(filesDir));
  if (!settings.autoPullOnTabFocus) {
    return false;
  }
  const token: string = settings.githubToken.trim();
  const gid: string = settings.gistId.trim();
  const fn: string = settings.gistFileName.trim().length > 0 ? settings.gistFileName.trim() :
    defaultGistSyncSettings().gistFileName;
  if (!gistCredentialsReady(token, gid, fn)) {
    return false;
  }
  if (isBookmarkGistDirty(filesDir)) {
    return false;
  }
  const bmPath: string = bookmarkCachePath(filesDir);
  const localSync: SyncDataInfo | null = await loadBookmarkSyncData(bmPath);
  const localTs: number = localSync !== null && localSync.createDate > 0 ? localSync.createDate : 0;
  const gistJson: string = await githubFetchGistRaw(token, gid);
  const fileText: string = await extractGistFileText(token, gistJson, fn);
  const remoteSync: SyncDataInfo | null = bookmarkPayloadFromParsedJson(JSON.parse(fileText) as object);
  if (remoteSync === null) {
    return false;
  }
  const remoteTs: number = remoteSync.createDate > 0 ? remoteSync.createDate : 0;
  if (remoteTs <= localTs) {
    return false;
  }
  saveBookmarkSyncData(bmPath, remoteSync);
  return true;
}
