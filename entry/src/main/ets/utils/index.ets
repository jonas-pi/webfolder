// ── 书签数据处理工具 ─────────────────────────────────────────────────────
export {
  bookmarkCollectDistinctFolderPaths,
  splitBookmarkFolderSegments,
  normalizeBookmarkFolderPath,
  bookmarkFolderPathDepthFromRaw,
  folderDepthFromFullPath,
  buildFolderTreeFromPaths,
  buildFolderTreeFromPathsOrdered,
  normalizeBookmarkUrlInput,
  validateBookmarkUrlReasonable,
  collectAllBookmarksFromGroups,
  decodeHtml,
  extractHost,
  faviconUrl,
  titleInitial,
  parseBookmarksFromHtml,
  groupBookmarks,
  cloneBookmarkGroups,
  groupBookmarksPreserveFolderOrder,
  bookmarkRootKeyForFolder,
  buildBookmarkNavForest,
  reorderBookmarkGroupsByForestSlots,
  reorderSiblingGroupsInBookmarkGroups,
  reorderArrayItems,
  removeBookmarkByKey,
  isFolderInExpandedList,
  parentFolderPathForExpand,
  folderPathAncestorChainForExpand,
  toggleFolderExpandSiblingExclusive,
  toggleFolderInExpandedList,
  backgroundMaskColorFromBrightness
} from './BookmarkUtils';

// ── 侧滑动画状态工具 ─────────────────────────────────────────────────────
export {
  swipeRowKeyFolder,
  swipeRowKeyBookmark,
  getSwipeTranslateX,
  upsertSwipeTranslate,
  removeSwipeTranslate,
  getSwipeAnimPhase,
  upsertSwipeAnimPhase,
  removeSwipeAnimPhase
} from './SwipeActionUtils';

// ── 背景图（含 GIF）────────────────────────────────────────────────────────
export { inferBackgroundFileSuffix, isBackgroundGifPath } from './BackgroundImageUtils';

// ── 动画工具（TransitionEffect 封装）────────────────────────────────────────
export {
  listScaleOpacityAppearTransition,
  iconScaleRotateAppearTransition,
  sheetEnterExitTransition
} from './AnimationUtils';

