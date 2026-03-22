import fs from '@ohos.file.fs';
import type { BookmarkItem, FaviconCacheItem, SettingsCache } from '../model/IndexTypes';
import { canAccessPath, writeTextFile } from './LocalFsService';

export function saveBookmarks(cachePath: string, items: Array<BookmarkItem>): void {
  writeTextFile(cachePath, JSON.stringify(items));
}

export async function loadBookmarks(cachePath: string): Promise<Array<BookmarkItem> | null> {
  if (!canAccessPath(cachePath)) {
    return null;
  }
  const content: string = await fs.readText(cachePath);
  if (content.length === 0) {
    return null;
  }
  return JSON.parse(content) as Array<BookmarkItem>;
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
