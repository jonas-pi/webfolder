export interface BookmarkItem {
  folder: string;
  title: string;
  url: string;
}

export interface BookmarkGroup {
  folder: string;
  items: Array<BookmarkItem>;
}

/** 主界面「收藏夹栏 /」下文件夹导航树（子文件夹嵌套在父级内展示） */
export interface BookmarkNavNode {
  folder: string;
  /** 本层显示名（路径最后一段） */
  segmentLabel: string;
  items: Array<BookmarkItem>;
  children: Array<BookmarkNavNode>;
}

export interface BookmarkNavForest {
  favBarGroup: BookmarkGroup | null;
  unclassifiedGroup: BookmarkGroup | null;
  /** 仅含「收藏夹栏 / xxx」一级根，子级在 children 内 */
  barFolderRoots: Array<BookmarkNavNode>;
}

export interface SettingsCache {
  backgroundImagePath: string;
  backgroundBlurLevel: string;
  backgroundBrightnessLevel: string;
  searchEngineIndex?: string;
  searchBoxPosition?: string;
}

export interface FaviconCacheItem {
  host: string;
  path: string;
}

export interface FolderTreeNode {
  fullPath: string;
  segmentLabel: string;
  children: Array<FolderTreeNode>;
}

export interface SearchEngineItem {
  name: string;
  prefix: string;
  icon: Resource;
}

export interface DialogButtonResult {
  index: number;
}

export interface SwipeTxEntry {
  key: string;
  x: number;
}

export interface SwipeAnimPhaseEntry {
  key: string;
  phase: number;
}
