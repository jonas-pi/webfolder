import { canAccessPath, readTextByFd, writeTextFile } from './LocalFsService';

/**
 * 本地书签是否在上次成功上传到 Gist 之后又发生过变更。
 * 为 true 时跳过「自动拉取」，避免覆盖尚未上传的编辑。
 */
export interface BookmarkGistLocalState {
  dirtySinceLastGistUpload: boolean;
}

export function bookmarkGistLocalStatePath(filesDir: string): string {
  return `${filesDir}/bookmark_gist_local_state.json`;
}

export function markBookmarkDirtyForGistSync(filesDir: string): void {
  const s: BookmarkGistLocalState = { dirtySinceLastGistUpload: true };
  writeTextFile(bookmarkGistLocalStatePath(filesDir), JSON.stringify(s));
}

export function clearBookmarkGistDirty(filesDir: string): void {
  const s: BookmarkGistLocalState = { dirtySinceLastGistUpload: false };
  writeTextFile(bookmarkGistLocalStatePath(filesDir), JSON.stringify(s));
}

export function isBookmarkGistDirty(filesDir: string): boolean {
  const p: string = bookmarkGistLocalStatePath(filesDir);
  if (!canAccessPath(p)) {
    return false;
  }
  try {
    const raw: string = readTextByFd(p);
    const obj: object = JSON.parse(raw) as object;
    const rec = obj as Record<string, boolean | undefined>;
    return rec['dirtySinceLastGistUpload'] === true;
  } catch (_e) {
    return false;
  }
}
