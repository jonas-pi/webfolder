import type { BookmarkGroup, BookmarkItem } from '../model/IndexTypes';
import {
  bookmarkFolderPathDepthFromRaw, collectAllBookmarksFromGroups, folderPathAncestorChainForExpand, groupBookmarks,
  normalizeBookmarkFolderPath, normalizeBookmarkUrlInput, validateBookmarkUrlReasonable
} from '../utils/BookmarkUtils';

export interface ServiceResult<T> {
  ok: boolean;
  error?: string;
  data?: T;
}

export interface NewBookmarkInput {
  titleRaw: string;
  urlRaw: string;
  useCustomFolder: boolean;
  customFolderRaw: string;
  selectedFolderRaw: string;
  folderMaxDepth: number;
}

export interface NewBookmarkOutput {
  allItems: Array<BookmarkItem>;
  nextGroups: Array<BookmarkGroup>;
  nextExpandedFolders: Array<string>;
  newItem: BookmarkItem;
}

export function confirmNewBookmarkFlow(
  input: NewBookmarkInput,
  groups: Array<BookmarkGroup>,
  expandedFolders: Array<string>
): ServiceResult<NewBookmarkOutput> {
  const title: string = input.titleRaw.trim();
  let folder: string = '';
  if (input.useCustomFolder) {
    folder = normalizeBookmarkFolderPath(input.customFolderRaw);
    if (folder.length === 0) {
      folder = '未分类';
    } else {
      const depth: number = bookmarkFolderPathDepthFromRaw(input.customFolderRaw);
      if (depth > input.folderMaxDepth) {
        return { ok: false, error: `文件夹最多 ${input.folderMaxDepth} 层（用「 / 」分隔）` };
      }
    }
  } else {
    folder = input.selectedFolderRaw.trim();
    if (folder.length === 0) {
      folder = '未分类';
    }
  }
  if (title.length === 0) {
    return { ok: false, error: '请输入名称' };
  }
  const url: string = normalizeBookmarkUrlInput(input.urlRaw);
  const urlErr: string | null = validateBookmarkUrlReasonable(url);
  if (urlErr !== null) {
    return { ok: false, error: urlErr };
  }

  const allItems: Array<BookmarkItem> = collectAllBookmarksFromGroups(groups);
  const newItem: BookmarkItem = { folder, title, url };
  allItems.push(newItem);

  let needExpand: boolean = true;
  let i: number = 0;
  while (i < expandedFolders.length) {
    if (expandedFolders[i] === folder) {
      needExpand = false;
      break;
    }
    i++;
  }

  const nextExpandedFolders: Array<string> = [];
  let j: number = 0;
  while (j < expandedFolders.length) {
    nextExpandedFolders.push(expandedFolders[j]);
    j++;
  }
  if (needExpand) {
    nextExpandedFolders.push(folder);
  }

  return {
    ok: true,
    data: {
      allItems,
      nextGroups: groupBookmarks(allItems),
      nextExpandedFolders,
      newItem
    }
  };
}

export interface RenameFolderOutput {
  allItems: Array<BookmarkItem>;
  nextExpandedFolders: Array<string>;
}

export function confirmRenameFolderFlow(
  oldPathRaw: string,
  newPathRaw: string,
  folderMaxDepth: number,
  groups: Array<BookmarkGroup>,
  expandedFolders: Array<string>
): ServiceResult<RenameFolderOutput> {
  const oldPath: string = oldPathRaw.trim();
  const newPath: string = normalizeBookmarkFolderPath(newPathRaw);
  if (newPath.length === 0) {
    return { ok: false, error: '请输入文件夹名称' };
  }
  if (newPath === oldPath) {
    return { ok: false, error: 'NOOP' };
  }
  const depth: number = bookmarkFolderPathDepthFromRaw(newPathRaw);
  if (depth > folderMaxDepth) {
    return { ok: false, error: `文件夹层级最多 ${folderMaxDepth} 层` };
  }

  const allItems: Array<BookmarkItem> = collectAllBookmarksFromGroups(groups);
  const oldPrefixWithSlash: string = oldPath + ' / ';
  let i: number = 0;
  while (i < allItems.length) {
    const curFolder: string = allItems[i].folder;
    if (curFolder === oldPath) {
      allItems[i] = { folder: newPath, title: allItems[i].title, url: allItems[i].url };
    } else if (curFolder.startsWith(oldPrefixWithSlash)) {
      const tail: string = curFolder.substring(oldPrefixWithSlash.length);
      const mapped: string = newPath + ' / ' + tail;
      allItems[i] = { folder: mapped, title: allItems[i].title, url: allItems[i].url };
    }
    i++;
  }

  const nextExpandedFolders: Array<string> = [];
  let ei: number = 0;
  while (ei < expandedFolders.length) {
    const f: string = expandedFolders[ei];
    if (f === oldPath) {
      nextExpandedFolders.push(newPath);
    } else if (f.startsWith(oldPrefixWithSlash)) {
      nextExpandedFolders.push(newPath + ' / ' + f.substring(oldPrefixWithSlash.length));
    } else {
      nextExpandedFolders.push(f);
    }
    ei++;
  }

  return { ok: true, data: { allItems, nextExpandedFolders } };
}

export function confirmDeleteFolderFlow(
  folder: string,
  groups: Array<BookmarkGroup>,
  expandedFolders: Array<string>
): ServiceResult<RenameFolderOutput> {
  const folderNorm: string = normalizeBookmarkFolderPath(folder);
  if (folderNorm.length === 0) {
    return { ok: false, error: '文件夹路径无效' };
  }
  const src: Array<BookmarkItem> = collectAllBookmarksFromGroups(groups);
  /** 删除该文件夹及其下所有子路径的书签（父删即整棵子树删除） */
  const prefixWithSlash: string = folderNorm + ' / ';
  const allItems: Array<BookmarkItem> = [];
  let i: number = 0;
  while (i < src.length) {
    const fNorm: string = normalizeBookmarkFolderPath(src[i].folder);
    if (fNorm !== folderNorm && !fNorm.startsWith(prefixWithSlash)) {
      allItems.push(src[i]);
    }
    i++;
  }
  const nextExpandedFolders: Array<string> = [];
  let j: number = 0;
  while (j < expandedFolders.length) {
    const efNorm: string = normalizeBookmarkFolderPath(expandedFolders[j]);
    if (efNorm !== folderNorm && !efNorm.startsWith(prefixWithSlash)) {
      nextExpandedFolders.push(expandedFolders[j]);
    }
    j++;
  }
  return { ok: true, data: { allItems, nextExpandedFolders } };
}

export interface EditBookmarkOutput {
  allItems: Array<BookmarkItem>;
  updatedItem: BookmarkItem;
}

export function confirmEditBookmarkFlow(
  folder: string,
  oldUrl: string,
  titleRaw: string,
  urlRaw: string,
  groups: Array<BookmarkGroup>
): ServiceResult<EditBookmarkOutput> {
  const title: string = titleRaw.trim();
  const url: string = normalizeBookmarkUrlInput(urlRaw);
  const urlErr: string | null = validateBookmarkUrlReasonable(url);
  if (urlErr !== null) {
    return { ok: false, error: urlErr };
  }
  if (title.length === 0) {
    return { ok: false, error: '请输入名称' };
  }

  const allItems: Array<BookmarkItem> = collectAllBookmarksFromGroups(groups);
  let i: number = 0;
  let found: boolean = false;
  while (i < allItems.length) {
    if (allItems[i].folder === folder && allItems[i].url === oldUrl) {
      allItems[i] = { folder, title, url };
      found = true;
      break;
    }
    i++;
  }
  if (!found) {
    return { ok: false, error: '未找到该书签' };
  }
  return { ok: true, data: { allItems, updatedItem: { folder, title, url } } };
}

export interface MoveBookmarkOutput {
  allItems: Array<BookmarkItem>;
  nextExpandedFolders: Array<string>;
}

export function confirmMoveBookmarkFlow(
  fromFolder: string,
  title: string,
  url: string,
  toFolderRaw: string,
  groups: Array<BookmarkGroup>,
  expandedFolders: Array<string>
): ServiceResult<MoveBookmarkOutput> {
  const toFolder: string = toFolderRaw.trim();
  if (toFolder.length === 0) {
    return { ok: false, error: '请选择目标文件夹' };
  }
  if (fromFolder === toFolder) {
    return { ok: false, error: 'NOOP' };
  }

  const allItems: Array<BookmarkItem> = collectAllBookmarksFromGroups(groups);
  let found: boolean = false;
  let i: number = 0;
  while (i < allItems.length) {
    if (!found && allItems[i].folder === fromFolder && allItems[i].url === url && allItems[i].title === title) {
      allItems[i] = { folder: toFolder, title, url };
      found = true;
      break;
    }
    i++;
  }
  if (!found) {
    return { ok: false, error: '未找到该书签' };
  }

  const nextExpandedFolders: Array<string> = [];
  let k: number = 0;
  while (k < expandedFolders.length) {
    nextExpandedFolders.push(expandedFolders[k]);
    k++;
  }
  const moveChain: Array<string> = folderPathAncestorChainForExpand(toFolder);
  let mi: number = 0;
  while (mi < moveChain.length) {
    const p: string = moveChain[mi];
    if (nextExpandedFolders.indexOf(p) < 0) {
      nextExpandedFolders.push(p);
    }
    mi++;
  }
  return { ok: true, data: { allItems, nextExpandedFolders } };
}
