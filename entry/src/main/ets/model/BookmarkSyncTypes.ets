/**
 * 与浏览器端 BookmarkHub 扩展的 Gist 载荷对齐的数据结构（见 BookmarkHub `SyncDataInfo` / `BookmarkInfo`）。
 * 根节点 title 必须使用下列常量，以便与扩展上传/下载的 JSON 互认。
 */
export interface BookmarkInfo {
  id?: string;
  parentId?: string;
  index?: number;
  url?: string;
  title: string;
  dateAdded?: number;
  dateGroupModified?: number;
  unmodifiable?: string;
  type?: string;
  children?: BookmarkInfo[];
}

/**
 * Gist 文件内顶层对象：与 BookmarkHub 字段一致，便于同一 Secret Gist 协同。
 */
export interface SyncDataInfo {
  browser: string;
  version: string;
  createDate: number;
  bookmarks: BookmarkInfo[];
}

/** 与 BookmarkHub `RootBookmarksType` 字符串完全一致 */
export class RootBookmarksType {
  static readonly MenuFolder: string = 'MenuFolder';
  static readonly ToolbarFolder: string = 'ToolbarFolder';
  static readonly UnfiledFolder: string = 'UnfiledFolder';
  static readonly MobileFolder: string = 'MobileFolder';
}
