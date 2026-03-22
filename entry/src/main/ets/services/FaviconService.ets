import fs from '@ohos.file.fs';
import http from '@ohos.net.http';
import type { BookmarkItem, FaviconCacheItem } from '../model/IndexTypes';
import { extractHost } from '../utils/BookmarkUtils';

export function faviconFilePath(filesDir: string, host: string): string {
  const safeHost: string = host.replaceAll('.', '_').replaceAll(':', '_');
  return `${filesDir}/favicon_${safeHost}.png`;
}

export function cachedFaviconPathByHost(cache: Array<FaviconCacheItem>, host: string): string {
  let i: number = 0;
  while (i < cache.length) {
    if (cache[i].host === host) {
      return cache[i].path;
    }
    i += 1;
  }
  return '';
}

export function faviconSourceForUrl(cache: Array<FaviconCacheItem>, url: string): string {
  const host: string = extractHost(url);
  if (host.length === 0) {
    return '';
  }
  const cachedPath: string = cachedFaviconPathByHost(cache, host);
  if (cachedPath.length > 0) {
    return `file://${cachedPath}`;
  }
  return `https://${host}/favicon.ico`;
}

export function upsertFaviconCache(
  cache: Array<FaviconCacheItem>,
  host: string,
  path: string
): Array<FaviconCacheItem> {
  let i: number = 0;
  while (i < cache.length) {
    if (cache[i].host === host) {
      const next: Array<FaviconCacheItem> = [];
      let j: number = 0;
      while (j < cache.length) {
        next.push(j === i ? { host, path } : cache[j]);
        j += 1;
      }
      return next;
    }
    i += 1;
  }
  const merged: Array<FaviconCacheItem> = [];
  let k: number = 0;
  while (k < cache.length) {
    merged.push(cache[k]);
    k += 1;
  }
  merged.push({ host, path });
  return merged;
}

export function isFaviconFailedForUrl(
  cache: Array<FaviconCacheItem>,
  failedHosts: Array<string>,
  url: string
): boolean {
  const host: string = extractHost(url);
  if (host.length === 0) {
    return true;
  }
  if (cachedFaviconPathByHost(cache, host).length > 0) {
    return false;
  }
  let i: number = 0;
  while (i < failedHosts.length) {
    if (failedHosts[i] === host) {
      return true;
    }
    i += 1;
  }
  return false;
}

export function markFaviconFailedForUrl(
  cache: Array<FaviconCacheItem>,
  failedHosts: Array<string>,
  url: string
): Array<string> {
  const host: string = extractHost(url);
  if (host.length === 0) {
    return failedHosts;
  }
  if (isFaviconFailedForUrl(cache, failedHosts, url)) {
    return failedHosts;
  }
  const next: Array<string> = [];
  let i: number = 0;
  while (i < failedHosts.length) {
    next.push(failedHosts[i]);
    i += 1;
  }
  next.push(host);
  return next;
}

export async function fetchAndCacheFavicon(
  url: string,
  cache: Array<FaviconCacheItem>,
  filesDir: string
): Promise<Array<FaviconCacheItem>> {
  const host: string = extractHost(url);
  if (host.length === 0 || cachedFaviconPathByHost(cache, host).length > 0) {
    return cache;
  }
  const request: http.HttpRequest = http.createHttp();
  try {
    const response: http.HttpResponse = await request.request(`https://${host}/favicon.ico`, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.ARRAY_BUFFER,
      connectTimeout: 1800,
      readTimeout: 1800
    });
    if (response.responseCode >= 200 && response.responseCode < 300 && response.result !== undefined) {
      const destPath: string = faviconFilePath(filesDir, host);
      const file: fs.File = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        if (response.result instanceof ArrayBuffer) {
          fs.writeSync(file.fd, response.result);
        }
      } finally {
        fs.closeSync(file);
      }
      return upsertFaviconCache(cache, host, destPath);
    }
    return cache;
  } catch (_) {
    return cache;
  } finally {
    request.destroy();
  }
}

export async function prefetchFavicons(
  items: Array<BookmarkItem>,
  cache: Array<FaviconCacheItem>,
  filesDir: string,
  workerCount: number = 4
): Promise<Array<FaviconCacheItem>> {
  const uniqueHosts: Array<string> = [];
  let i: number = 0;
  while (i < items.length) {
    const host: string = extractHost(items[i].url);
    if (host.length > 0 && cachedFaviconPathByHost(cache, host).length === 0) {
      let exists: boolean = false;
      let j: number = 0;
      while (j < uniqueHosts.length) {
        if (uniqueHosts[j] === host) {
          exists = true;
          break;
        }
        j += 1;
      }
      if (!exists) {
        uniqueHosts.push(host);
      }
    }
    i += 1;
  }

  let nextCache: Array<FaviconCacheItem> = cache;
  let cursor: number = 0;
  const workers: Array<Promise<void>> = [];
  let w: number = 0;
  while (w < workerCount) {
    const worker: Promise<void> = (async () => {
      while (cursor < uniqueHosts.length) {
        const nextIndex: number = cursor;
        cursor += 1;
        const host: string = uniqueHosts[nextIndex];
        nextCache = await fetchAndCacheFavicon(`https://${host}/`, nextCache, filesDir);
      }
    })();
    workers.push(worker);
    w += 1;
  }
  await Promise.all(workers);
  return nextCache;
}
