import type { BookmarkGroup, BookmarkItem } from '../model/IndexTypes';

export interface BookmarkPageVm {
  bookmarkGroups: Array<BookmarkGroup>;
  bookmarkSwipeRestoreKey: number;
  swipeActionIconBtn: number;
  optionRowMinHeight: number;
  optionRowPadH: number;
  optionRowPadV: number;
  optionCardRadius: number;
  rowClickEffect: ClickEffect;
  contentPrimary: Resource;
  contentSecondary: Resource;
  isFolderExpanded: (folder: string) => boolean;
  onToggleFolder: (folder: string) => void;
  isFaviconFailed: (url: string) => boolean;
  faviconSource: (url: string) => string;
  markFaviconFailed: (url: string) => void;
  titleInitial: (title: string) => string;
  itemTransition: (itemIndex: number) => TransitionEffect;
  onOpenBookmark: (url: string) => void;
  onReorderBookmarkItems: (folder: string, from: number, to: number) => void;
  onReorderBookmarkGroups: (from: number, to: number) => void;
  onReorderChildFolders: (parentFolderPath: string, from: number, to: number) => void;
  folderSwipeTranslateX: (folder: string) => number;
  bookmarkSwipeTranslateX: (folder: string, url: string) => number;
  onFolderSwipeVisibleRatio: (folder: string, ratio: number) => void;
  onBookmarkSwipeVisibleRatio: (folder: string, url: string, ratio: number) => void;
  onStartRenameFolder: (folder: string) => void;
  onDeleteFolder: (folder: string) => void;
  onMoveBookmark: (folder: string, item: BookmarkItem) => void;
  onEditBookmark: (folder: string, item: BookmarkItem) => void;
  onDeleteBookmark: (folder: string, item: BookmarkItem) => void;
  onEmptyAppear: () => void;
}
