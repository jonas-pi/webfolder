import type { BookmarkItem } from '../model/IndexTypes';
import type { BookmarkPageVm } from '../types/ViewModels';

export interface BookmarkPageVmMapperInput extends BookmarkPageVm {}

export function mapBookmarkPageVm(input: BookmarkPageVmMapperInput): BookmarkPageVm {
  return {
    bookmarkGroups: input.bookmarkGroups,
    bookmarkSwipeRestoreKey: input.bookmarkSwipeRestoreKey,
    swipeActionIconBtn: input.swipeActionIconBtn,
    optionRowMinHeight: input.optionRowMinHeight,
    optionRowPadH: input.optionRowPadH,
    optionRowPadV: input.optionRowPadV,
    optionCardRadius: input.optionCardRadius,
    rowClickEffect: input.rowClickEffect,
    contentPrimary: input.contentPrimary,
    contentSecondary: input.contentSecondary,
    isFolderExpanded: input.isFolderExpanded,
    onToggleFolder: input.onToggleFolder,
    isFaviconFailed: input.isFaviconFailed,
    faviconSource: input.faviconSource,
    markFaviconFailed: input.markFaviconFailed,
    titleInitial: input.titleInitial,
    itemTransition: input.itemTransition,
    onOpenBookmark: input.onOpenBookmark,
    onReorderBookmarkItems: input.onReorderBookmarkItems,
    onReorderBookmarkGroups: input.onReorderBookmarkGroups,
    onReorderChildFolders: input.onReorderChildFolders,
    folderSwipeTranslateX: input.folderSwipeTranslateX,
    bookmarkSwipeTranslateX: input.bookmarkSwipeTranslateX,
    onFolderSwipeVisibleRatio: input.onFolderSwipeVisibleRatio,
    onBookmarkSwipeVisibleRatio: input.onBookmarkSwipeVisibleRatio,
    onStartRenameFolder: input.onStartRenameFolder,
    onDeleteFolder: input.onDeleteFolder,
    onMoveBookmark: input.onMoveBookmark,
    onEditBookmark: input.onEditBookmark,
    onDeleteBookmark: input.onDeleteBookmark,
    onEmptyAppear: input.onEmptyAppear
  };
}

export interface BookmarkSheetVm {
  fromFolder: string;
  targetFolder: string;
  title: string;
  url: string;
  folderPaths: Array<string>;
}

export function mapMoveBookmarkSheetVm(
  fromFolder: string,
  targetFolder: string,
  title: string,
  url: string,
  folderPaths: Array<string>
): BookmarkSheetVm {
  return { fromFolder, targetFolder, title, url, folderPaths };
}

export interface BookmarkRowOpsVm {
  onMove: (folder: string, item: BookmarkItem) => void;
  onEdit: (folder: string, item: BookmarkItem) => void;
  onDelete: (folder: string, item: BookmarkItem) => void;
}

export function mapBookmarkRowOps(
  onMove: (folder: string, item: BookmarkItem) => void,
  onEdit: (folder: string, item: BookmarkItem) => void,
  onDelete: (folder: string, item: BookmarkItem) => void
): BookmarkRowOpsVm {
  return { onMove, onEdit, onDelete };
}
