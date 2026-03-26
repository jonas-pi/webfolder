import fs from '@ohos.file.fs';
import type { BookmarkItem, FaviconCacheItem, SettingsCache } from '../model/IndexTypes';
import type { SyncDataInfo } from '../model/BookmarkSyncTypes';
import {
  bookmarkPayloadFromParsedJson,
  flatItemsFromSyncData,
  flatItemsToSyncData
} from '../utils/BookmarkHubSyncConverter';
import { clearBookmarkGistDirty, markBookmarkDirtyForGistSync } from './BookmarkGistLocalState';
import { canAccessPath, readTextByFd, writeTextFile } from './LocalFsService';

function parentDirFromBookmarkCachePath(cachePath: string): string {
  const i: number = cachePath.lastIndexOf('/');
  return i >= 0 ? cachePath.substring(0, i) : '';
}

/**
 * 持久化为与 BookmarkHub 扩展一致的 SyncDataInfo JSON（便于同一 Gist 协同）。
 * 旧版「纯 BookmarkItem 数组」在加载时会自动识别并迁移为树形载荷的等价扁平数据。
 * 本地编辑保留 createDate，便于与 Gist 比较；并标记待上传以免自动拉取覆盖未推送的修改。
 */
export function saveBookmarks(cachePath: string, items: Array<BookmarkItem>): void {
  let prevCreateDate: number | undefined = undefined;
  if (canAccessPath(cachePath)) {
    try {
      const txt: string = readTextByFd(cachePath);
      const existing: SyncDataInfo | null = bookmarkPayloadFromParsedJson(JSON.parse(txt) as object);
      if (existing !== null && existing.createDate > 0) {
        prevCreateDate = existing.createDate;
      }
    } catch (_e) {
      prevCreateDate = undefined;
    }
  }
  const sync: SyncDataInfo = flatItemsToSyncData(items, prevCreateDate);
  writeTextFile(cachePath, JSON.stringify(sync));
  const dir: string = parentDirFromBookmarkCachePath(cachePath);
  if (dir.length > 0) {
    markBookmarkDirtyForGistSync(dir);
  }
}

export async function loadBookmarks(cachePath: string): Promise<Array<BookmarkItem> | null> {
  if (!canAccessPath(cachePath)) {
    return null;
  }
  const content: string = await fs.readText(cachePath);
  if (content.length === 0) {
    return null;
  }
  const parsed: object = JSON.parse(content) as object;
  const sync: SyncDataInfo | null = bookmarkPayloadFromParsedJson(parsed);
  if (sync === null) {
    return null;
  }
  return flatItemsFromSyncData(sync);
}

/** 读取完整同步载荷（例如后续接 Gist 上传时可原样提交） */
export async function loadBookmarkSyncData(cachePath: string): Promise<SyncDataInfo | null> {
  if (!canAccessPath(cachePath)) {
    return null;
  }
  const content: string = await fs.readText(cachePath);
  if (content.length === 0) {
    return null;
  }
  return bookmarkPayloadFromParsedJson(JSON.parse(content) as object);
}

/** 将扩展/Gist 拉取的 SyncDataInfo 写入本地缓存文件，并清除「待上传」标记 */
export function saveBookmarkSyncData(cachePath: string, sync: SyncDataInfo): void {
  writeTextFile(cachePath, JSON.stringify(sync));
  const dir: string = parentDirFromBookmarkCachePath(cachePath);
  if (dir.length > 0) {
    clearBookmarkGistDirty(dir);
  }
}

export function saveFaviconCache(cachePath: string, cache: Array<FaviconCacheItem>): void {
  writeTextFile(cachePath, JSON.stringify(cache));
}

export async function loadFaviconCache(cachePath: string): Promise<Array<FaviconCacheItem> | null> {
  if (!canAccessPath(cachePath)) {
    return null;
  }
  const content: string = await fs.readText(cachePath);
  if (content.length === 0) {
    return null;
  }
  return JSON.parse(content) as Array<FaviconCacheItem>;
}

export function saveSettingsCache(cachePath: string, settings: SettingsCache): void {
  writeTextFile(cachePath, JSON.stringify(settings));
}

export async function loadSettingsCache(cachePath: string): Promise<SettingsCache | null> {
  if (!canAccessPath(cachePath)) {
    return null;
  }
  const content: string = await fs.readText(cachePath);
  if (content.length === 0) {
    return null;
  }
  return JSON.parse(content) as SettingsCache;
}
