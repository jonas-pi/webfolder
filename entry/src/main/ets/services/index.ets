// ── 书签业务流（增/删/改/移/重命名）────────────────────────────────────────
export {
  confirmNewBookmarkFlow,
  confirmRenameFolderFlow,
  confirmDeleteFolderFlow,
  confirmEditBookmarkFlow,
  confirmMoveBookmarkFlow
} from './BookmarkService';

// ── Favicon 缓存与预取 ───────────────────────────────────────────────────
export {
  faviconSourceForUrl,
  isFaviconFailedForUrl,
  markFaviconFailedForUrl,
  prefetchFavicons,
  fetchAndCacheFavicon,
  upsertFaviconCache,
  faviconFilePath,
  cachedFaviconPathByHost
} from './FaviconService';

// ── 持久化（书签/favicon/设置 读写） ─────────────────────────────────────
export {
  saveBookmarks,
  loadBookmarks,
  loadBookmarkSyncData,
  saveBookmarkSyncData,
  saveFaviconCache,
  loadFaviconCache,
  saveSettingsCache,
  loadSettingsCache
} from './BookmarkStorageService';

export {
  defaultGistSyncSettings,
  saveGistSyncSettings,
  loadGistSyncSettings
} from './GistSettingsStorageService';

export {
  githubFetchGistRaw,
  extractGistFileText,
  githubPatchGistFiles
} from './GithubGistApi';

export {
  remoteFetchGistRaw,
  remoteExtractGistFileText,
  remotePatchGistFiles
} from './RemoteGistSyncApi';

export {
  runGistAutoUploadFromDisk,
  tryGistAutoPullFromDisk,
  GIST_AUTO_UPLOAD_DEBOUNCE_MS
} from './BookmarkGistAutoSyncService';

export { isBookmarkGistDirty } from './BookmarkGistLocalState';

// ── 设置（序列化/反序列化） ──────────────────────────────────────────────
export { buildSettingsCache, applySettingsCache } from './SettingsService';

export {
  PRIVACY_POLICY_PAGE_URL,
  hasAcceptedPrivacyPolicy,
  setPrivacyPolicyAccepted
} from './PrivacyConsentService';

// ── 本地文件系统工具 ─────────────────────────────────────────────────────
export {
  canAccessPath,
  normalizePickerUriToPath,
  readTextByFd,
  copyByFd,
  readBookmarkFileText,
  writeTextFile
} from './LocalFsService';
