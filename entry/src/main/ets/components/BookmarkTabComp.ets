import { common, Want } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';
import vibrator from '@ohos.vibrator';
import picker from '@ohos.file.picker';
import {
  BookmarkGroup, BookmarkItem, DialogButtonResult, FaviconCacheItem, SwipeTxEntry, SwipeAnimPhaseEntry
} from '../model';
import { activeCredentialsFromSettings } from '../model/GistSyncSettings';
import {
  SWIPE_ACTION_SLIDE_VP, SWIPE_ACTION_ICON_BTN_VP, OPTION_ROW_MIN_HEIGHT_VP,
  OPTION_ROW_PAD_H_VP, OPTION_ROW_PAD_V_VP, OPTION_CARD_RADIUS_VP, BOOKMARK_NODE_APPEAR_MS,
  TOAST_DURATION_SHORT_MS, TOAST_DURATION_LONG_MS, SHEET_NONE, SHEET_NEW_BOOKMARK,
  SHEET_RENAME_FOLDER, SHEET_EDIT_BOOKMARK, SHEET_MOVE_BOOKMARK, SHEET_MODE_RESET_DELAY_MS,
  BOOKMARK_FOLDER_MAX_DEPTH, NEW_BOOKMARK_FOLDER_ROW_HEIGHT_VP
} from '../constants/AppLayout';
import {
  buildFolderTreeFromPathsOrdered,
  buildBookmarkNavForest,
  collectAllBookmarksFromGroups,
  cloneBookmarkGroups,
  folderDepthFromFullPath, groupBookmarks, groupBookmarksPreserveFolderOrder, normalizeBookmarkFolderPath,
  parseBookmarksFromHtml, titleInitial,
  reorderBookmarkGroupsByForestSlots,
  reorderSiblingGroupsInBookmarkGroups,
  isFolderInExpandedList, toggleFolderExpandSiblingExclusive,
  reorderArrayItems, removeBookmarkByKey,
  getSwipeAnimPhase as resolveSwipeAnimPhase, getSwipeTranslateX as resolveSwipeTranslateX,
  removeSwipeAnimPhase as removeSwipeAnimPhaseEntry, removeSwipeTranslate as removeSwipeTranslateEntry,
  swipeRowKeyBookmark as buildSwipeRowKeyBookmark, swipeRowKeyFolder as buildSwipeRowKeyFolder,
  upsertSwipeAnimPhase as upsertSwipeAnimPhaseEntry, upsertSwipeTranslate as upsertSwipeTranslateEntry
} from '../utils';
import {
  confirmNewBookmarkFlow, confirmRenameFolderFlow, confirmDeleteFolderFlow,
  confirmEditBookmarkFlow, confirmMoveBookmarkFlow,
  faviconSourceForUrl, isFaviconFailedForUrl, markFaviconFailedForUrl,
  prefetchFavicons as prefetchFaviconsByService,
  loadBookmarks, loadFaviconCache, saveBookmarks, saveFaviconCache,
  readBookmarkFileText as fsReadBookmarkFileText,
  runGistAutoUploadFromDisk, tryGistAutoPullFromDisk, GIST_AUTO_UPLOAD_DEBOUNCE_MS,
  loadGistSyncSettings, loadBookmarkSyncData, saveBookmarkSyncData,
  remotePatchGistFiles, remoteFetchGistRaw, remoteExtractGistFileText, isBookmarkGistDirty
} from '../services';
import { flatItemsToSyncData, bookmarkPayloadFromParsedJson } from '../utils/BookmarkHubSyncConverter';
import {
  BuildNewBookmarkSheet, BuildFolderRenameSheet, BuildBookmarkEditSheet,
  BuildMoveBookmarkSheet, BuildSheetFallbackClose, resolveSheetRoute,
  SHEET_ROUTE_NEW_BOOKMARK, SHEET_ROUTE_RENAME_FOLDER, SHEET_ROUTE_MOVE_BOOKMARK,
  SHEET_ROUTE_EDIT_BOOKMARK, SHEET_ROUTE_FALLBACK_CLOSE
} from './sheets';
import { BookmarkPageComp } from './bookmark';
import { MainTabTitleBar } from './chrome/MainTabTitleBar';
import { clearPendingShare, peekPendingShare } from '../utils/ShareReceive';

// ── 书签 Tab：书签列表 + 所有书签操作面板 ─────────────────────────────────────
@Component
export struct BookmarkTabComp {
  // 跨组件共享状态（@Provide 来自 Index.ets）
  @Watch('onNewBookmarkReqChanged') @Consume('openNewBookmarkReq') openNewBookmarkReq: number = 0;
  @Watch('onImportBookmarksReqChanged') @Consume('importBookmarksReq') importBookmarksReq: number = 0;
  @Watch('onBackPressCloseChanged') @Consume('backPressCloseReq') backPressCloseReq: number = 0;
  /** 设置页从 Gist 拉取后递增，此处 Watch 触发从磁盘刷新列表（不弹「已恢复」Toast） */
  @Watch('onBookmarkDataReloadReqChanged') @Consume('bookmarkDataReloadReq') bookmarkDataReloadReq: number = 0;
  /** 从其它 Tab 回到收藏夹时递增，尝试按配置自动从 Gist 拉取 */
  @Watch('onBookmarkGistAutoPullReqChanged') @Consume('bookmarkGistAutoPullReq') bookmarkGistAutoPullReq: number = 0;
  @Watch('onOpenSharePrefillReqChanged') @Consume('openSharePrefillReq') openSharePrefillReq: number = 0;
  @Consume('anySheetOpen') anySheetOpen: boolean;

  // 书签列表状态
  @State private bookmarkGroups: Array<BookmarkGroup> = [];
  @State private expandedFolders: Array<string> = [];
  /** 每次提交书签分组时递增，配合容器 .id() 强制子树重建（解决「仅引用未变、第二帧起不刷新」） */
  @State private bookmarkRenderEpoch: number = 0;
  // 侧滑动画状态
  @State private bookmarkSwipeRestoreKey: number = 0;
  @State private swipeActionTranslateEntries: Array<SwipeTxEntry> = [];
  @State private swipeAnimPhaseEntries: Array<SwipeAnimPhaseEntry> = [];
  private swipeActionLastRatioByKey: Map<string, number> = new Map();
  // 新建收藏表单
  @State private newBookmarkTitle: string = '';
  @State private newBookmarkUrl: string = '';
  @State private newBookmarkSelectedFolderPath: string = '未分类';
  @State private newBookmarkIsCustomFolder: boolean = false;
  /** 根级自定义：整段路径；在父下新建时置空，改用 locked + child */
  @State private newBookmarkFolderCustomPath: string = '';
  /** true：与「新建文件夹（根级）」对应；false：树中「在此文件夹下新建」 */
  @State private newBookmarkCustomIsRootLevel: boolean = true;
  /** 存储用父路径前缀，含「收藏夹栏 / 」并以「 / 」结尾 */
  @State private newBookmarkCustomLockedStoragePrefix: string = '';
  @State private newBookmarkCustomChildInput: string = '';
  @State private expandedNewBookmarkFolderPaths: Array<string> = [];
  // 文件夹操作
  @State private folderLongPressTarget: string = '';
  @State private folderRenameInput: string = '';
  // 移动书签
  @State private moveBookmarkFromFolder: string = '';
  @State private moveBookmarkTitle: string = '';
  @State private moveBookmarkUrl: string = '';
  @State private moveBookmarkTargetFolder: string = '';
  @State private moveBookmarkExpandedFolderPaths: Array<string> = [];
  // 编辑书签
  @State private bookmarkEditFolder: string = '';
  @State private bookmarkEditOldUrl: string = '';
  @State private bookmarkEditTitle: string = '';
  @State private bookmarkEditUrl: string = '';
  // Favicon 缓存
  @State private faviconCache: Array<FaviconCacheItem> = [];
  @State private failedFaviconHosts: Array<string> = [];
  // 本地半模态
  @State private sheetVisible: boolean = false;
  @State private sheetMode: number = SHEET_NONE;
  private sheetModeResetTimer: number = -1;
  /** 顶栏「+」菜单打开时的旋转角（与 Index 原 MainHeader 行为一致） */
  @State private plusRotation: number = 0;
  /** 手动同步：上传中旋转角（定时递增，配合 .animation 平滑） */
  @State private manualSyncIconAngle: number = 0;
  /** 手动同步进行中，禁用重复点击 */
  @State private manualGistSyncBusy: boolean = false;
  /** Gist 自动上传防抖定时器 id（clearTimeout 用） */
  private gistAutoUploadTimerId: number = -1;
  /** 手动同步图标旋转定时器 */
  private manualSyncSpinTimerId: number = -1;

  // ── @Watch 响应入口触发 ───────────────────────────────────────────────────
  private onNewBookmarkReqChanged(): void { this.openNewBookmarkSheet(); }
  private onImportBookmarksReqChanged(): void { this.importBookmarks(); }
  private onBackPressCloseChanged(): void { if (this.sheetVisible) { this.closeModalSheet(); } }
  private onBookmarkDataReloadReqChanged(): void {
    if (this.bookmarkDataReloadReq <= 0) {
      return;
    }
    this.loadBookmarksFromLocal(false)
      .then((): void => {
        this.prefetchFavicons(collectAllBookmarksFromGroups(this.bookmarkGroups)).catch((_e: Object) => {});
      })
      .catch((_err: Object) => {
        this.showCapsuleToast('书签刷新失败', true);
      });
  }

  private onBookmarkGistAutoPullReqChanged(): void {
    if (this.bookmarkGistAutoPullReq <= 0) {
      return;
    }
    this.tryRunGistAutoPullFromCloud(false).catch((_e: Object) => {});
  }

  private onOpenSharePrefillReqChanged(): void {
    if (this.openSharePrefillReq <= 0) {
      return;
    }
    const pending = peekPendingShare();
    if (pending === null) {
      return;
    }
    clearPendingShare();
    this.openNewBookmarkSheetWithSharePrefill(pending.url, pending.title);
  }

  /** 应用 filesDir，供 Gist 自动同步读写路径 */
  private appFilesDir(): string {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return ctx.filesDir;
  }

  private cancelGistAutoUploadDebounce(): void {
    if (this.gistAutoUploadTimerId !== -1) {
      clearTimeout(this.gistAutoUploadTimerId);
      this.gistAutoUploadTimerId = -1;
    }
  }

  /**
   * 本地书签已写盘后调度防抖上传（由「云端同步」里开关控制，未开启则 runGistAutoUploadFromDisk 内立即返回）。
   */
  private scheduleGistAutoUploadAfterLocalSave(): void {
    this.cancelGistAutoUploadDebounce();
    const dir: string = this.appFilesDir();
    this.gistAutoUploadTimerId = setTimeout((): void => {
      this.gistAutoUploadTimerId = -1;
      runGistAutoUploadFromDisk(dir).catch((_e: Object) => {});
    }, GIST_AUTO_UPLOAD_DEBOUNCE_MS);
  }

  /**
   * @param fromColdStart 冷启动延迟路径不弹 Toast，避免与「已恢复」叠在一起
   */
  private async tryRunGistAutoPullFromCloud(fromColdStart: boolean): Promise<void> {
    try {
      const applied: boolean = await tryGistAutoPullFromDisk(this.appFilesDir());
      if (applied) {
        this.bookmarkDataReloadReq = this.bookmarkDataReloadReq + 1;
        if (!fromColdStart) {
          this.showCapsuleToast('已从云端更新书签');
        }
      }
    } catch (_e) {
      // 网络失败等静默，避免打扰；用户可手动拉取
    }
  }

  // ── Toast / 震动 ──────────────────────────────────────────────────────────
  private showCapsuleToast(msg: string, longDuration: boolean = false): void {
    if (msg.length === 0) { return; }
    try {
      this.getUIContext().getPromptAction().showToast({
        message: msg,
        duration: longDuration ? TOAST_DURATION_LONG_MS : TOAST_DURATION_SHORT_MS
      });
    } catch (_err) {}
  }

  private lightHaptic(): void {
    vibrator.startVibration({ type: 'time', duration: 10 }, { id: 0, usage: 'touch' })
      .catch((): void => {});
  }

  @Builder
  private BookmarkAddMenuBuilder() {
    Menu() {
      MenuItem({ content: '新建收藏' })
        .onClick(() => {
          this.plusRotation = 0;
          this.openNewBookmarkReq++;
        })
      MenuItem({ content: '导入收藏' })
        .onClick(() => {
          this.plusRotation = 0;
          this.lightHaptic();
          this.importBookmarksReq++;
        })
    }
  }

  // ── 文件路径 ──────────────────────────────────────────────────────────────
  private bookmarkCachePath(): string {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return `${ctx.filesDir}/bookmarks_cache.json`;
  }

  private gistSettingsCachePath(): string {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return `${ctx.filesDir}/gist_sync_settings.json`;
  }

  /** 开始旋转「同步」官方符号（上传过程中保持转动） */
  private startManualGistSyncSpin(): void {
    if (this.manualSyncSpinTimerId !== -1) {
      clearInterval(this.manualSyncSpinTimerId);
      this.manualSyncSpinTimerId = -1;
    }
    this.manualGistSyncBusy = true;
    this.manualSyncIconAngle = 0;
    this.manualSyncSpinTimerId = setInterval((): void => {
      this.manualSyncIconAngle = (this.manualSyncIconAngle + 24) % 360;
    }, 42);
  }

  /** 停止旋转并恢复可点击 */
  private stopManualGistSyncSpin(): void {
    if (this.manualSyncSpinTimerId !== -1) {
      clearInterval(this.manualSyncSpinTimerId);
      this.manualSyncSpinTimerId = -1;
    }
    this.manualGistSyncBusy = false;
    this.manualSyncIconAngle = 0;
  }

  /**
   * 顶栏手动同步：先拉取 Gist 与本地 SyncDataInfo.createDate 比对。
   * - 本地有未推送编辑（dirty）：优先上传，避免被旧时间戳误判。
   * - 否则远端较新 → 拉取覆盖；本地较新 → 上传；时间戳相同 → 提示无需操作。
   */
  private async onManualGistBidirectionalSync(): Promise<void> {
    if (this.manualGistSyncBusy) {
      return;
    }
    this.lightHaptic();
    const filesDir: string = this.appFilesDir();
    const s = await loadGistSyncSettings(this.gistSettingsCachePath());
    const a = activeCredentialsFromSettings(s);
    const token: string = a.gistToken.trim();
    const gid: string = a.gistId.trim();
    const fn: string = a.gistFileName;
    if (token.length === 0 || gid.length === 0 || fn.length === 0) {
      this.showCapsuleToast('请先在「我的 → 云端同步」填写令牌、片段 ID 与文件名');
      return;
    }
    this.cancelGistAutoUploadDebounce();
    this.showCapsuleToast('正在与云端比对并同步…');
    this.startManualGistSyncSpin();
    const bmPath: string = this.bookmarkCachePath();
    try {
      const dirty: boolean = isBookmarkGistDirty(filesDir);
      let localSync = await loadBookmarkSyncData(bmPath);
      const localTs: number =
        localSync !== null && localSync.createDate > 0 ? localSync.createDate : 0;

      const gistJson: string = await remoteFetchGistRaw(s);
      const fileText: string = await remoteExtractGistFileText(s, gistJson, fn);
      const remoteSync = bookmarkPayloadFromParsedJson(JSON.parse(fileText) as object);
      if (remoteSync === null) {
        this.showCapsuleToast('云端书签文件格式无效', true);
        return;
      }
      const remoteTs: number = remoteSync.createDate > 0 ? remoteSync.createDate : 0;

      /** 本地自上次成功同步后又有改动：以本机为准直接上传，避免被「仅时间戳较旧」误伤 */
      if (dirty) {
        if (localSync === null) {
          localSync = flatItemsToSyncData([]);
        }
        localSync.createDate = Date.now();
        localSync.browser = 'HarmonyOS/HM';
        await remotePatchGistFiles(s, fn, JSON.stringify(localSync));
        saveBookmarkSyncData(bmPath, localSync);
        this.showCapsuleToast('本地有未推送修改，已上传到云端');
        return;
      }

      if (remoteTs > localTs) {
        saveBookmarkSyncData(bmPath, remoteSync);
        this.bookmarkDataReloadReq = this.bookmarkDataReloadReq + 1;
        this.showCapsuleToast('云端较新，已拉取书签');
        return;
      }
      if (localTs > remoteTs) {
        if (localSync === null) {
          localSync = flatItemsToSyncData([]);
        }
        localSync.createDate = Date.now();
        localSync.browser = 'HarmonyOS/HM';
        await remotePatchGistFiles(s, fn, JSON.stringify(localSync));
        saveBookmarkSyncData(bmPath, localSync);
        this.showCapsuleToast('本地较新，已上传到云端');
        return;
      }

      this.showCapsuleToast('本地与云端版本一致');
    } catch (e) {
      this.showCapsuleToast(`同步失败：${JSON.stringify(e)}`, true);
    } finally {
      this.stopManualGistSyncSpin();
    }
  }

  private faviconCachePath(): string {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return `${ctx.filesDir}/favicon_cache.json`;
  }

  // ── 半模态管理 ─────────────────────────────────────────────────────────────
  private cancelPendingSheetModeReset(): void {
    if (this.sheetModeResetTimer !== -1) {
      clearTimeout(this.sheetModeResetTimer);
      this.sheetModeResetTimer = -1;
    }
  }

  private scheduleSheetModeResetAfterDismiss(): void {
    this.cancelPendingSheetModeReset();
    this.sheetModeResetTimer = setTimeout((): void => {
      this.sheetMode = SHEET_NONE;
      this.sheetModeResetTimer = -1;
    }, SHEET_MODE_RESET_DELAY_MS);
  }

  private closeModalSheet(): void {
    this.sheetVisible = false;
    this.anySheetOpen = false;
    this.scheduleSheetModeResetAfterDismiss();
    setTimeout((): void => { this.lightHaptic(); }, 0);
  }

  private openSheet(mode: number): void {
    this.lightHaptic();
    this.cancelPendingSheetModeReset();
    this.sheetMode = mode;
    this.sheetVisible = true;
    this.anySheetOpen = true;
  }

  // ── 侧滑动画 ──────────────────────────────────────────────────────────────
  private clearBookmarkSwipeActionAnimState(): void {
    this.swipeActionTranslateEntries = [];
    this.swipeAnimPhaseEntries = [];
    this.swipeActionLastRatioByKey.clear();
  }

  private refreshBookmarkSwipeSurface(): void {
    this.clearBookmarkSwipeActionAnimState();
    this.bookmarkSwipeRestoreKey = this.bookmarkSwipeRestoreKey + 1;
  }

  private getSwipeTranslateX(key: string): number {
    return resolveSwipeTranslateX(this.swipeActionTranslateEntries, key);
  }

  private setSwipeTranslateX(key: string, x: number): void {
    this.swipeActionTranslateEntries = upsertSwipeTranslateEntry(this.swipeActionTranslateEntries, key, x);
  }

  private removeSwipeTranslate(key: string): void {
    this.swipeActionTranslateEntries = removeSwipeTranslateEntry(this.swipeActionTranslateEntries, key);
  }

  private getSwipeAnimPhase(key: string): number {
    return resolveSwipeAnimPhase(this.swipeAnimPhaseEntries, key);
  }

  private setSwipeAnimPhase(key: string, phase: number): void {
    this.swipeAnimPhaseEntries = upsertSwipeAnimPhaseEntry(this.swipeAnimPhaseEntries, key, phase);
  }

  private removeSwipeAnimPhase(key: string): void {
    this.swipeAnimPhaseEntries = removeSwipeAnimPhaseEntry(this.swipeAnimPhaseEntries, key);
  }

  private handleSwipeActionVisibleRatio(key: string, currentRatio: number): void {
    const prev: number = this.swipeActionLastRatioByKey.has(key) ?
      (this.swipeActionLastRatioByKey.get(key) as number) : -1;
    this.swipeActionLastRatioByKey.set(key, currentRatio);
    const phase: number = this.getSwipeAnimPhase(key);
    if (phase === 2) { return; }
    const enterTh: number = 0.16;
    const exitTh: number = 0.32;
    const opening: boolean = currentRatio > prev;
    const closing: boolean = currentRatio < prev;
    if (phase === 0 && opening && prev < enterTh && currentRatio >= enterTh) {
      this.playSwipePanelEnter(key);
    }
    if (phase !== 2 && closing && prev > exitTh && currentRatio <= exitTh) {
      this.playSwipePanelExit(key);
    }
  }

  private playSwipePanelEnter(key: string): void {
    this.setSwipeAnimPhase(key, 1);
    this.setSwipeTranslateX(key, SWIPE_ACTION_SLIDE_VP);
    this.getUIContext().animateTo({ duration: 320, curve: curves.springMotion() }, () => {
      this.setSwipeTranslateX(key, 0);
      this.setSwipeAnimPhase(key, 0);
    });
  }

  private playSwipePanelExit(key: string): void {
    this.setSwipeAnimPhase(key, 2);
    this.getUIContext().animateTo({ duration: 180, curve: Curve.Sharp }, () => {
      this.setSwipeTranslateX(key, SWIPE_ACTION_SLIDE_VP);
    });
    setTimeout((): void => {
      this.removeSwipeTranslate(key);
      this.removeSwipeAnimPhase(key);
      this.swipeActionLastRatioByKey.delete(key);
    }, 200);
  }

  // ── Favicon ────────────────────────────────────────────────────────────────
  private faviconSource(url: string): string {
    return faviconSourceForUrl(this.faviconCache, url);
  }

  private isFaviconFailed(url: string): boolean {
    return isFaviconFailedForUrl(this.faviconCache, this.failedFaviconHosts, url);
  }

  private markFaviconFailed(url: string): void {
    this.failedFaviconHosts = markFaviconFailedForUrl(this.faviconCache, this.failedFaviconHosts, url);
  }

  private async prefetchFavicons(items: Array<BookmarkItem>): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const nextCache: Array<FaviconCacheItem> =
      await prefetchFaviconsByService(items, this.faviconCache, ctx.filesDir, 4);
    if (nextCache !== this.faviconCache) {
      this.faviconCache = nextCache;
      saveFaviconCache(this.faviconCachePath(), this.faviconCache);
    }
  }

  // ── 书签持久化 ─────────────────────────────────────────────────────────────
  private async saveBookmarksToLocal(items: Array<BookmarkItem>): Promise<void> {
    saveBookmarks(this.bookmarkCachePath(), items);
    this.scheduleGistAutoUploadAfterLocalSave();
  }

  /**
   * @param showRestoreToast true：启动恢复时提示条数；false：Gist 等静默刷新后由调用方已 Toast
   */
  private async loadBookmarksFromLocal(showRestoreToast: boolean = true): Promise<void> {
    const restored = await loadBookmarks(this.bookmarkCachePath());
    if (restored === null) { return; }
    // 本地 JSON 数组顺序即导入/HTML 顺序，用默认分组即可
    this.expandedFolders = [];
    this.commitBookmarkGroups(groupBookmarks(restored));
    this.bookmarkSwipeRestoreKey = this.bookmarkSwipeRestoreKey + 1;
    if (showRestoreToast) {
      this.showCapsuleToast(`已恢复 ${restored.length} 条书签`);
    }
  }

  private async loadFaviconCacheFromLocal(): Promise<void> {
    const restored = await loadFaviconCache(this.faviconCachePath());
    if (restored === null) { return; }
    this.faviconCache = restored;
  }

  /** 写入书签分组：克隆引用链并递增 bookmarkRenderEpoch，避免 ArkTS 因引用未变跳过 UI 刷新 */
  private commitBookmarkGroups(next: Array<BookmarkGroup>): void {
    this.bookmarkRenderEpoch = this.bookmarkRenderEpoch + 1;
    this.bookmarkGroups = cloneBookmarkGroups(next);
  }

  /**
   * 对当前分组再克隆一次并提交（用于 Sheet 关闭/异步写盘后仍不刷新的机型）。
   * 不改变业务数据，仅产生新引用 + 递增 epoch。
   */
  private forceBookmarkUiRefresh(): void {
    this.commitBookmarkGroups(this.bookmarkGroups);
  }

  /** 延后一帧再强制刷新，避免与 bindSheet 动画、写盘回调抢同一帧 */
  private scheduleBookmarkUiRefresh(delayMs: number = 48): void {
    setTimeout((): void => {
      this.forceBookmarkUiRefresh();
    }, delayMs);
  }

  /** 当前主界面文件夹顺序，用于持久化时保持与拖拽/导入顺序一致 */
  private folderOrderHintFromGroups(): Array<string> {
    const r: Array<string> = [];
    let i: number = 0;
    while (i < this.bookmarkGroups.length) {
      r.push(this.bookmarkGroups[i].folder);
      i++;
    }
    return r;
  }

  private async persistBookmarksFromFlat(allItems: Array<BookmarkItem>): Promise<void> {
    // 在覆盖 bookmarkGroups 之前读取顺序提示（移动/编辑后仍沿用原文件夹排列）
    const hint: Array<string> = this.folderOrderHintFromGroups();
    // 先按新数据更新内存与 UI，再异步写盘；避免「已删除」的文件夹仍显示到读盘完成前
    this.commitBookmarkGroups(groupBookmarksPreserveFolderOrder(allItems, hint));
    this.bookmarkSwipeRestoreKey = this.bookmarkSwipeRestoreKey + 1;
    await this.saveBookmarksToLocal(allItems);
    // 写盘后再读回，同步磁盘；仅当「条数与本次写入一致」时才覆盖内存，避免读回旧缓存把已删除数据又画出来
    const reloaded: Array<BookmarkItem> | null = await loadBookmarks(this.bookmarkCachePath());
    if (reloaded !== null && reloaded.length === allItems.length) {
      this.commitBookmarkGroups(groupBookmarksPreserveFolderOrder(reloaded, hint));
    }
    // 状态已批量写入 @State；用 0ms 动画包一层，促使框架尽快提交下一帧（部分机型上异步写盘后需多一次调度）
    try {
      this.getUIContext().animateTo({ duration: 0, curve: Curve.Linear }, (): void => {});
    } catch (_e) {}
  }

  // ── 书签操作 ───────────────────────────────────────────────────────────────
  private bookmarkNodeAppearTransition(itemIndex: number): TransitionEffect {
    return TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .animation({ duration: BOOKMARK_NODE_APPEAR_MS, curve: curves.springMotion(), delay: itemIndex * 10 + 30 });
  }

  private toggleFolder(folder: string): void {
    this.lightHaptic();
    this.getUIContext().animateTo({ duration: 400, curve: Curve.Friction }, () => {
      // 同级仅一个展开，父子可同时展开；收起父时一并收起子路径
      const nextExp: Array<string> = toggleFolderExpandSiblingExclusive(this.expandedFolders, folder);
      this.expandedFolders = [...nextExp];
    });
  }

  private reorderBookmarkGroups(from: number, to: number): void {
    const forest = buildBookmarkNavForest(this.bookmarkGroups);
    const next: Array<BookmarkGroup> | null =
      reorderBookmarkGroupsByForestSlots(this.bookmarkGroups, forest, from, to);
    if (next === null) { return; }
    this.commitBookmarkGroups(next);
    this.persistBookmarksFromFlat(collectAllBookmarksFromGroups(next)).catch((_e: Object) => {});
  }

  /** 父文件夹展开区内：同级子文件夹分组拖拽排序 */
  private reorderChildFoldersUnderParent(parentPath: string, from: number, to: number): void {
    const next: Array<BookmarkGroup> | null =
      reorderSiblingGroupsInBookmarkGroups(this.bookmarkGroups, parentPath, from, to);
    if (next === null) { return; }
    this.commitBookmarkGroups(next);
    this.persistBookmarksFromFlat(collectAllBookmarksFromGroups(next)).catch((_e: Object) => {});
  }

  private reorderBookmarkItemsInFolder(folder: string, from: number, to: number): void {
    let gi: number = 0;
    while (gi < this.bookmarkGroups.length) {
      if (this.bookmarkGroups[gi].folder === folder) {
        const nextItems: Array<BookmarkItem> | null =
          reorderArrayItems(this.bookmarkGroups[gi].items, from, to);
        if (nextItems === null) { return; }
        const newGroups: Array<BookmarkGroup> = [];
        let j: number = 0;
        while (j < this.bookmarkGroups.length) {
          newGroups.push(j === gi ? { folder: folder, items: nextItems } : this.bookmarkGroups[j]);
          j++;
        }
        this.commitBookmarkGroups(newGroups);
        this.persistBookmarksFromFlat(collectAllBookmarksFromGroups(newGroups)).catch((_e: Object) => {});
        return;
      }
      gi++;
    }
  }

  private async openBookmark(url: string): Promise<void> {
    try {
      this.lightHaptic();
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await ctx.startAbility({ deviceId: '', action: 'ohos.want.action.viewData', uri: url } as Want);
    } catch (err) {
      this.showCapsuleToast(`打开失败: ${JSON.stringify(err)}`, true);
    }
  }

  // ── 新建收藏 ───────────────────────────────────────────────────────────────

  /**
   * 按主界面 bookmarkGroups 顺序收集所有文件夹的"显示用短路径"（去掉"收藏夹栏 / "前缀）。
   * 不做额外排序，保证选择器文件夹顺序与主界面拖拽排列完全一致。
   */
  private strippedFolderPaths(): Array<string> {
    const prefix: string = '收藏夹栏 / ';
    const result: Array<string> = [];
    let i: number = 0;
    while (i < this.bookmarkGroups.length) {
      const p: string = this.bookmarkGroups[i].folder;
      if (p !== '收藏夹栏') {
        const stripped: string = p.startsWith(prefix) ? p.slice(prefix.length) : p;
        if (stripped.length > 0 && result.indexOf(stripped) < 0) {
          result.push(stripped);
        }
      }
      i++;
    }
    return result;
  }

  /**
   * 将 strippedFolderPaths() 返回的显示用短路径还原为实际存储路径。
   * 若 "收藏夹栏 / {stripped}" 在当前分组中存在，则返回完整路径，否则原样返回。
   */
  private restoreFullFolderPath(stripped: string): string {
    if (stripped.length === 0) {
      return '';
    }
    const full: string = '收藏夹栏 / ' + stripped;
    let i: number = 0;
    while (i < this.bookmarkGroups.length) {
      if (this.bookmarkGroups[i].folder === full) {
        return full;
      }
      i++;
    }
    return stripped;
  }

  /** 新建收藏 UI：与主列表一致，去掉「收藏夹栏 / 」前缀展示 */
  private displayFolderPathWithoutBookmarkBarPrefix(storagePath: string): string {
    const prefix: string = '收藏夹栏 / ';
    if (storagePath.startsWith(prefix)) {
      return storagePath.slice(prefix.length);
    }
    return storagePath;
  }

  private openNewBookmarkSheet(): void {
    this.newBookmarkTitle = '';
    this.newBookmarkUrl = '';
    // 不预选文件夹，强制用户主动选择保存位置
    this.newBookmarkSelectedFolderPath = '';
    this.newBookmarkIsCustomFolder = false;
    this.newBookmarkFolderCustomPath = '';
    this.newBookmarkCustomIsRootLevel = true;
    this.newBookmarkCustomLockedStoragePrefix = '';
    this.newBookmarkCustomChildInput = '';
    this.expandedNewBookmarkFolderPaths = [];
    this.openSheet(SHEET_NEW_BOOKMARK);
  }

  /** 自浏览器等系统分享入口：预填标题与网址，仍须用户选择文件夹 */
  private openNewBookmarkSheetWithSharePrefill(url: string, title: string): void {
    this.newBookmarkTitle = title.trim();
    this.newBookmarkUrl = url.trim();
    this.newBookmarkSelectedFolderPath = '';
    this.newBookmarkIsCustomFolder = false;
    this.newBookmarkFolderCustomPath = '';
    this.newBookmarkCustomIsRootLevel = true;
    this.newBookmarkCustomLockedStoragePrefix = '';
    this.newBookmarkCustomChildInput = '';
    this.expandedNewBookmarkFolderPaths = [];
    this.openSheet(SHEET_NEW_BOOKMARK);
  }

  private async confirmNewBookmark(): Promise<void> {
    // 未选择文件夹且未输入自定义路径时，拦截并提示
    if (!this.newBookmarkIsCustomFolder && this.newBookmarkSelectedFolderPath.length === 0) {
      this.showCapsuleToast('请在"文件夹"中选择一个保存位置');
      return;
    }
    if (this.newBookmarkIsCustomFolder && !this.newBookmarkCustomIsRootLevel &&
      this.newBookmarkCustomChildInput.trim().length === 0) {
      this.showCapsuleToast('请输入新文件夹名称');
      return;
    }
    let customFolderRaw: string = '';
    if (this.newBookmarkIsCustomFolder) {
      if (this.newBookmarkCustomIsRootLevel) {
        customFolderRaw = this.newBookmarkFolderCustomPath;
      } else {
        customFolderRaw = this.newBookmarkCustomLockedStoragePrefix + this.newBookmarkCustomChildInput;
      }
    }
    const flow = confirmNewBookmarkFlow({
      titleRaw: this.newBookmarkTitle, urlRaw: this.newBookmarkUrl,
      useCustomFolder: this.newBookmarkIsCustomFolder,
      customFolderRaw: customFolderRaw,
      // 将显示用的短路径还原为实际存储路径（"工作" → "收藏夹栏 / 工作"）
      selectedFolderRaw: this.restoreFullFolderPath(this.newBookmarkSelectedFolderPath),
      folderMaxDepth: BOOKMARK_FOLDER_MAX_DEPTH
    }, this.bookmarkGroups, this.expandedFolders);
    if (!flow.ok || flow.data === undefined) {
      if (flow.error !== undefined) { this.showCapsuleToast(flow.error); }
      return;
    }
    try {
      this.lightHaptic();
      this.expandedFolders = [...flow.data.nextExpandedFolders];
      // 与删除/移动共用：先内存刷新再写盘；避免读回旧文件导致「新建不显示、重启才出现」
      await this.persistBookmarksFromFlat(flow.data.allItems);
      this.prefetchFavicons([flow.data.newItem]).catch((_e: Object) => {});
      this.closeModalSheet();
      this.showCapsuleToast('已添加收藏');
      this.scheduleBookmarkUiRefresh(64);
    } catch (err) {
      this.showCapsuleToast(`添加失败: ${JSON.stringify(err)}`, true);
    }
  }

  private async importBookmarks(): Promise<void> {
    try {
      this.lightHaptic();
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker();
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['HTML|.html,.htm'];
      const uris: Array<string> = await documentPicker.select(options);
      if (uris.length === 0) { return; }
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const html: string = await fsReadBookmarkFileText(uris[0], ctx.cacheDir);
      const parsed: Array<BookmarkItem> = parseBookmarksFromHtml(html);
      this.expandedFolders = [];
      this.commitBookmarkGroups(groupBookmarks(parsed));
      this.bookmarkSwipeRestoreKey = this.bookmarkSwipeRestoreKey + 1;
      await this.saveBookmarksToLocal(parsed);
      const reloadedImp: Array<BookmarkItem> | null = await loadBookmarks(this.bookmarkCachePath());
      if (reloadedImp !== null && reloadedImp.length === parsed.length) {
        this.commitBookmarkGroups(groupBookmarks(reloadedImp));
      }
      this.prefetchFavicons(parsed).catch((_err: Object) => {});
      this.showCapsuleToast(`导入完成，共 ${parsed.length} 条`);
      this.scheduleBookmarkUiRefresh(64);
    } catch (err) {
      this.showCapsuleToast(`导入失败: ${JSON.stringify(err)}`, true);
    }
  }

  // ── 文件夹操作 ─────────────────────────────────────────────────────────────
  private startRenameFolderFromSwipe(folder: string): void {
    this.refreshBookmarkSwipeSurface();
    this.folderLongPressTarget = folder;
    this.folderRenameInput = folder;
    this.openSheet(SHEET_RENAME_FOLDER);
  }

  private promptDeleteFolderFromSwipe(folder: string): void {
    this.refreshBookmarkSwipeSurface();
    this.lightHaptic();
    this.folderLongPressTarget = folder;
    setTimeout((): void => {
      try {
        this.getUIContext().getPromptAction().showDialog({
          title: '删除文件夹',
          message: `确定删除文件夹「${this.displayFolderPathWithoutBookmarkBarPrefix(folder)}」及其下全部子文件夹与书签吗？此操作不可撤销。`,
          buttons: [{ text: '取消', color: '#000000' }, { text: '删除', color: '#E84026' }]
        }).then((result: DialogButtonResult) => {
          if (result.index === 1) {
            this.performDeleteFolder(folder).catch((_e: Object) => {});
          }
        }).catch((_e: Object) => {});
      } catch (_e) { this.showCapsuleToast('无法打开确认对话框', true); }
    }, 100);
  }

  private async confirmRenameFolder(): Promise<void> {
    const flow = confirmRenameFolderFlow(
      this.folderLongPressTarget, this.folderRenameInput,
      BOOKMARK_FOLDER_MAX_DEPTH, this.bookmarkGroups, this.expandedFolders);
    if (!flow.ok || flow.data === undefined) {
      if (flow.error === 'NOOP') { this.closeModalSheet(); return; }
      if (flow.error !== undefined) { this.showCapsuleToast(flow.error); }
      return;
    }
    try {
      this.lightHaptic();
      this.expandedFolders = [...flow.data.nextExpandedFolders];
      await this.persistBookmarksFromFlat(flow.data.allItems);
      this.closeModalSheet();
      this.showCapsuleToast('已重命名文件夹');
      this.scheduleBookmarkUiRefresh(64);
    } catch (err) { this.showCapsuleToast(`重命名失败: ${JSON.stringify(err)}`, true); }
  }

  private async performDeleteFolder(folder: string): Promise<void> {
    try {
      this.lightHaptic();
      const targetPath: string = this.canonicalFolderPathForDelete(folder);
      const flow = confirmDeleteFolderFlow(targetPath, this.bookmarkGroups, this.expandedFolders);
      if (!flow.ok || flow.data === undefined) {
        if (flow.error !== undefined) { this.showCapsuleToast(flow.error); }
        return;
      }
      this.expandedFolders = [...flow.data.nextExpandedFolders];
      await this.persistBookmarksFromFlat(flow.data.allItems);
      this.showCapsuleToast('已删除文件夹');
      this.scheduleBookmarkUiRefresh(64);
    } catch (err) { this.showCapsuleToast(`删除失败: ${JSON.stringify(err)}`, true); }
  }

  /**
   * 删除操作用：与分组中已有路径对齐（空格/斜杠写法），无单独分组时（仅作树节点父路径）仍用规范化路径。
   */
  private canonicalFolderPathForDelete(raw: string): string {
    const n: string = normalizeBookmarkFolderPath(raw.trim());
    if (n.length === 0) {
      return raw.trim();
    }
    let gi: number = 0;
    while (gi < this.bookmarkGroups.length) {
      const g: string = this.bookmarkGroups[gi].folder;
      if (normalizeBookmarkFolderPath(g) === n) {
        return g;
      }
      gi++;
    }
    return n;
  }

  // ── 书签单条操作 ───────────────────────────────────────────────────────────
  private openBookmarkEditSheet(folder: string, item: BookmarkItem): void {
    this.refreshBookmarkSwipeSurface();
    this.bookmarkEditFolder = folder;
    this.bookmarkEditOldUrl = item.url;
    this.bookmarkEditTitle = item.title;
    this.bookmarkEditUrl = item.url;
    this.openSheet(SHEET_EDIT_BOOKMARK);
  }

  private async confirmEditBookmark(): Promise<void> {
    const flow = confirmEditBookmarkFlow(
      this.bookmarkEditFolder, this.bookmarkEditOldUrl,
      this.bookmarkEditTitle, this.bookmarkEditUrl, this.bookmarkGroups);
    if (!flow.ok || flow.data === undefined) {
      if (flow.error !== undefined) { this.showCapsuleToast(flow.error); }
      return;
    }
    try {
      this.lightHaptic();
      await this.persistBookmarksFromFlat(flow.data.allItems);
      this.prefetchFavicons([flow.data.updatedItem]).catch((_e: Object) => {});
      this.closeModalSheet();
      this.showCapsuleToast('已保存修改');
      this.scheduleBookmarkUiRefresh(64);
    } catch (err) { this.showCapsuleToast(`保存失败: ${JSON.stringify(err)}`, true); }
  }

  private promptDeleteBookmarkConfirm(folder: string, item: BookmarkItem): void {
    this.refreshBookmarkSwipeSurface();
    this.lightHaptic();
    setTimeout((): void => {
      try {
        this.getUIContext().getPromptAction().showDialog({
          title: '删除书签', message: `确定删除「${item.title}」吗？`,
          buttons: [{ text: '取消', color: '#000000' }, { text: '删除', color: '#E84026' }]
        }).then((result: DialogButtonResult) => {
          if (result.index === 1) {
            this.performDeleteOneBookmark(folder, item.url).catch((_e: Object) => {});
          }
        }).catch((_e: Object) => {});
      } catch (_e) { this.showCapsuleToast('无法打开确认对话框', true); }
    }, 80);
  }

  private async performDeleteOneBookmark(folder: string, url: string): Promise<void> {
    try {
      this.lightHaptic();
      const next: Array<BookmarkItem> =
        removeBookmarkByKey(collectAllBookmarksFromGroups(this.bookmarkGroups), folder, url);
      await this.persistBookmarksFromFlat(next);
      this.showCapsuleToast('已删除书签');
      this.scheduleBookmarkUiRefresh(64);
    } catch (err) { this.showCapsuleToast(`删除失败: ${JSON.stringify(err)}`, true); }
  }

  private openBookmarkMoveSheet(fromFolder: string, item: BookmarkItem): void {
    this.refreshBookmarkSwipeSurface();
    this.moveBookmarkFromFolder = fromFolder;
    this.moveBookmarkTitle = item.title;
    this.moveBookmarkUrl = item.url;
    // 不预选文件夹，强制用户主动选择目标位置，避免与当前文件夹相同时误触 NOOP
    this.moveBookmarkTargetFolder = '';
    this.moveBookmarkExpandedFolderPaths = [];
    this.openSheet(SHEET_MOVE_BOOKMARK);
  }

  private async confirmMoveBookmarkToTargetFolder(): Promise<void> {
    const flow = confirmMoveBookmarkFlow(
      this.moveBookmarkFromFolder, this.moveBookmarkTitle, this.moveBookmarkUrl,
      // 将显示用的短路径还原为实际存储路径（"工作" → "收藏夹栏 / 工作"）
      this.restoreFullFolderPath(this.moveBookmarkTargetFolder),
      this.bookmarkGroups, this.expandedFolders);
    if (!flow.ok || flow.data === undefined) {
      if (flow.error === 'NOOP') { this.closeModalSheet(); return; }
      if (flow.error !== undefined) { this.showCapsuleToast(flow.error); }
      return;
    }
    try {
      this.lightHaptic();
      this.expandedFolders = [...flow.data.nextExpandedFolders];
      await this.persistBookmarksFromFlat(flow.data.allItems);
      this.closeModalSheet();
      this.showCapsuleToast('已移动到目标文件夹');
      this.scheduleBookmarkUiRefresh(64);
    } catch (err) { this.showCapsuleToast(`移动失败: ${JSON.stringify(err)}`, true); }
  }

  // ── Sheet Builders ─────────────────────────────────────────────────────────
  private currentSheetRoute(): number {
    return resolveSheetRoute(this.sheetMode, this.sheetVisible);
  }

  @Builder
  private UnifiedSheetBuilder() {
    if (this.currentSheetRoute() === SHEET_ROUTE_NEW_BOOKMARK) {
      BuildNewBookmarkSheet({
        navChromeBg: $r('sys.color.ohos_id_color_sub_background'),
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        contentTertiary: $r('sys.color.ohos_id_color_text_tertiary'),
        optionRowPadH: OPTION_ROW_PAD_H_VP,
        newBookmarkFolderRowHeight: NEW_BOOKMARK_FOLDER_ROW_HEIGHT_VP,
        optionCardRadius: OPTION_CARD_RADIUS_VP,
        folderMaxDepth: BOOKMARK_FOLDER_MAX_DEPTH,
        rowClickEffect: { level: ClickEffectLevel.MIDDLE, scale: 0.95 },
        iconClickEffect: { level: ClickEffectLevel.LIGHT, scale: 0.95 },
        newBookmarkTitle: this.newBookmarkTitle,
        newBookmarkUrl: this.newBookmarkUrl,
        newBookmarkIsCustomFolder: this.newBookmarkIsCustomFolder,
        newBookmarkCustomIsRootLevel: this.newBookmarkCustomIsRootLevel,
        newBookmarkSelectedFolderPath: this.newBookmarkSelectedFolderPath,
        newBookmarkFolderCustomPath: this.newBookmarkFolderCustomPath,
        newBookmarkCustomLockedDisplayPrefix:
          this.displayFolderPathWithoutBookmarkBarPrefix(this.newBookmarkCustomLockedStoragePrefix),
        newBookmarkCustomChildInput: this.newBookmarkCustomChildInput,
        folderTree: buildFolderTreeFromPathsOrdered(this.strippedFolderPaths()),
        isFolderExpanded: (fullPath: string): boolean =>
          isFolderInExpandedList(this.expandedNewBookmarkFolderPaths, fullPath),
        folderDepthFromFullPath: (path: string): number => folderDepthFromFullPath(path),
        onBack: (): void => { this.closeModalSheet(); },
        onTitleChange: (value: string): void => { this.newBookmarkTitle = value; },
        onUrlChange: (value: string): void => { this.newBookmarkUrl = value; },
        onSelectFolder: (fullPath: string): void => {
          this.lightHaptic();
          this.newBookmarkSelectedFolderPath = fullPath;
          this.newBookmarkIsCustomFolder = false;
          this.newBookmarkCustomIsRootLevel = true;
          this.newBookmarkCustomLockedStoragePrefix = '';
          this.newBookmarkCustomChildInput = '';
        },
        onToggleFolderExpand: (fullPath: string): void => {
          this.lightHaptic();
          this.expandedNewBookmarkFolderPaths =
            toggleFolderExpandSiblingExclusive(this.expandedNewBookmarkFolderPaths, fullPath);
        },
        onEnableRootCustomFolder: (): void => {
          this.lightHaptic();
          this.newBookmarkIsCustomFolder = true;
          this.newBookmarkCustomIsRootLevel = true;
          this.newBookmarkFolderCustomPath = '';
          this.newBookmarkCustomLockedStoragePrefix = '';
          this.newBookmarkCustomChildInput = '';
        },
        onCreateChildFolder: (fullPath: string): void => {
          this.lightHaptic();
          this.newBookmarkIsCustomFolder = true;
          this.newBookmarkCustomIsRootLevel = false;
          this.newBookmarkFolderCustomPath = '';
          // folderTree 的 fullPath 为显示用短路径（已去掉「收藏夹栏 / 」），须还原为实际存储路径后再追加子文件夹
          this.newBookmarkCustomLockedStoragePrefix = `${this.restoreFullFolderPath(fullPath)} / `;
          this.newBookmarkCustomChildInput = '';
        },
        onCustomPathChange: (value: string): void => { this.newBookmarkFolderCustomPath = value; },
        onCustomChildInputChange: (value: string): void => { this.newBookmarkCustomChildInput = value; },
        onConfirmAdd: (): void => { this.confirmNewBookmark().catch((_e: Object) => {}); }
      });
    } else if (this.currentSheetRoute() === SHEET_ROUTE_RENAME_FOLDER) {
      BuildFolderRenameSheet({
        navChromeBg: $r('sys.color.ohos_id_color_sub_background'),
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        folderRenameInput: this.folderRenameInput,
        onBack: (): void => { this.closeModalSheet(); },
        onInputChange: (v: string): void => { this.folderRenameInput = v; },
        onConfirm: (): void => { this.confirmRenameFolder().catch((_e: Object) => {}); }
      });
    } else if (this.currentSheetRoute() === SHEET_ROUTE_EDIT_BOOKMARK) {
      BuildBookmarkEditSheet({
        navChromeBg: $r('sys.color.ohos_id_color_sub_background'),
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        rowHeight: NEW_BOOKMARK_FOLDER_ROW_HEIGHT_VP,
        bookmarkEditTitle: this.bookmarkEditTitle,
        bookmarkEditUrl: this.bookmarkEditUrl,
        onBack: (): void => { this.closeModalSheet(); },
        onTitleChange: (value: string): void => { this.bookmarkEditTitle = value; },
        onUrlChange: (value: string): void => { this.bookmarkEditUrl = value; },
        onSave: (): void => { this.confirmEditBookmark().catch((_e: Object) => {}); }
      });
    } else if (this.currentSheetRoute() === SHEET_ROUTE_MOVE_BOOKMARK) {
      BuildMoveBookmarkSheet({
        navChromeBg: $r('sys.color.ohos_id_color_sub_background'),
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        optionRowPadH: OPTION_ROW_PAD_H_VP,
        rowHeight: OPTION_ROW_MIN_HEIGHT_VP,
        iconClickEffect: { level: ClickEffectLevel.LIGHT },
        moveBookmarkTitle: this.moveBookmarkTitle,
        moveBookmarkTargetFolder: this.moveBookmarkTargetFolder,
        folderTree: buildFolderTreeFromPathsOrdered(this.strippedFolderPaths()),
        isFolderExpanded: (fullPath: string): boolean => {
          return this.moveBookmarkExpandedFolderPaths.indexOf(fullPath) >= 0;
        },
        onBack: (): void => { this.closeModalSheet(); },
        onSelectTarget: (path: string): void => {
          this.lightHaptic();
          this.moveBookmarkTargetFolder = path;
        },
        onToggleFolderExpand: (fullPath: string): void => {
          this.lightHaptic();
          this.moveBookmarkExpandedFolderPaths =
            toggleFolderExpandSiblingExclusive(this.moveBookmarkExpandedFolderPaths, fullPath);
        },
        onConfirmMove: (): void => {
          this.confirmMoveBookmarkToTargetFolder().catch((_e: Object) => {});
        }
      });
    } else if (this.currentSheetRoute() === SHEET_ROUTE_FALLBACK_CLOSE) {
      BuildSheetFallbackClose({
        navChromeBg: $r('sys.color.ohos_id_color_sub_background'),
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        onBack: (): void => { this.closeModalSheet(); }
      });
    }
  }

  // ── 生命周期 ───────────────────────────────────────────────────────────────
  aboutToAppear(): void {
    this.loadBookmarksFromLocal(true).catch((_err: Object) => {
      this.showCapsuleToast('书签恢复失败，请重新导入', true);
    });
    this.loadFaviconCacheFromLocal().then(() => {
      this.prefetchFavicons(collectAllBookmarksFromGroups(this.bookmarkGroups)).catch((_err: Object) => {});
    }).catch((_err: Object) => {});
    // 冷启动若在收藏夹 Tab：延迟一次自动拉取（与切换到本 Tab 的 Watch 互补）
    setTimeout((): void => {
      this.tryRunGistAutoPullFromCloud(true).catch((_e: Object) => {});
    }, 900);
  }

  aboutToDisappear(): void {
    this.cancelGistAutoUploadDebounce();
    this.stopManualGistSyncSpin();
  }

  // ── build ─────────────────────────────────────────────────────────────────
  build() {
    Column() {
      // 标题属于本 Tab 内容区；尾部必须用「子组件块」绑定 @BuilderParam trailing（传 trailing: this.xxx 在真机上易为 undefined → trailing() 崩溃）
      MainTabTitleBar({ title: '收藏夹' }) {
        Row({ space: 0 }) {
          // 系统 Symbol：双箭头环形；与加号拉开间距，整体略远离右边缘
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.arrow_2_circlepath'))
              .fontSize(22)
              .fontColor([$r('sys.color.icon_secondary')])
              .rotate({ angle: this.manualSyncIconAngle })
              .animation({ duration: 38, curve: Curve.Linear })
          }
          .width(40)
          .height(40)
          .margin({ right: 18 })
          .backgroundColor($r('app.color.back_button_bg'))
          .enabled(!this.manualGistSyncBusy)
          .opacity(this.manualGistSyncBusy ? 0.55 : 1)
          .clickEffect({ level: ClickEffectLevel.LIGHT })
          .onClick((): void => {
            this.onManualGistBidirectionalSync().catch((_e: Object) => {});
          })

          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(24)
            .fontColor([$r('sys.color.icon_secondary')])
            .rotate({ angle: this.plusRotation })
            .animation({ duration: 280, curve: Curve.FastOutSlowIn })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.plusRotation = 135;
              }
            })
            .bindMenu(this.BookmarkAddMenuBuilder, {
              onDisappear: (): void => {
                animateTo({ duration: 0 }, () => {
                  this.plusRotation = 0;
                });
              }
            })
        }
        .justifyContent(FlexAlign.End)
        // 尾栏整体略离右边缘，同步按钮相对加号更靠左
        .margin({ right: 10 })
      }
      // 用 ForEach + 数据版本字符串作唯一 key，强制销毁并重建 BookmarkPageComp，
      // 避免仅 @Prop 更新时 List/侧滑子树在 Tabs/Sheet 场景下被复用导致「数据已变界面不变」。
      Column() {
        ForEach(
          [`${this.bookmarkRenderEpoch}_${this.bookmarkSwipeRestoreKey}`],
          (_k: string) => {
          BookmarkPageComp({
            bookmarkGroups: this.bookmarkGroups,
            bookmarkRenderEpoch: this.bookmarkRenderEpoch,
            bookmarkSwipeRestoreKey: this.bookmarkSwipeRestoreKey,
            swipeActionTranslateEntries: this.swipeActionTranslateEntries,
            expandedFolders: this.expandedFolders,
            swipeActionIconBtn: SWIPE_ACTION_ICON_BTN_VP,
            optionRowMinHeight: OPTION_ROW_MIN_HEIGHT_VP,
            optionRowPadH: OPTION_ROW_PAD_H_VP,
            optionRowPadV: OPTION_ROW_PAD_V_VP,
            optionCardRadius: OPTION_CARD_RADIUS_VP,
            rowClickEffect: { level: ClickEffectLevel.MIDDLE, scale: 0.95 },
            contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
            contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
            isFolderExpanded: (folder: string): boolean =>
              isFolderInExpandedList(this.expandedFolders, folder),
            onToggleFolder: (folder: string): void => { this.toggleFolder(folder); },
            isFaviconFailed: (url: string): boolean => this.isFaviconFailed(url),
            faviconSource: (url: string): string => this.faviconSource(url),
            markFaviconFailed: (url: string): void => { this.markFaviconFailed(url); },
            titleInitial: (title: string): string => titleInitial(title),
            itemTransition: (itemIndex: number): TransitionEffect =>
              this.bookmarkNodeAppearTransition(itemIndex),
            onOpenBookmark: (url: string): void => { this.openBookmark(url); },
            onReorderBookmarkItems: (folder: string, from: number, to: number): void => {
              this.reorderBookmarkItemsInFolder(folder, from, to);
            },
            onReorderBookmarkGroups: (from: number, to: number): void => {
              this.reorderBookmarkGroups(from, to);
            },
            onReorderChildFolders: (parentPath: string, from: number, to: number): void => {
              this.reorderChildFoldersUnderParent(parentPath, from, to);
            },
            folderSwipeTranslateX: (folder: string): number =>
              this.getSwipeTranslateX(buildSwipeRowKeyFolder(folder)),
            bookmarkSwipeTranslateX: (folder: string, url: string): number =>
              this.getSwipeTranslateX(buildSwipeRowKeyBookmark(folder, url)),
            onFolderSwipeVisibleRatio: (folder: string, ratio: number): void => {
              this.handleSwipeActionVisibleRatio(buildSwipeRowKeyFolder(folder), ratio);
            },
            onBookmarkSwipeVisibleRatio: (folder: string, url: string, ratio: number): void => {
              this.handleSwipeActionVisibleRatio(buildSwipeRowKeyBookmark(folder, url), ratio);
            },
            onStartRenameFolder: (folder: string): void => { this.startRenameFolderFromSwipe(folder); },
            onDeleteFolder: (folder: string): void => { this.promptDeleteFolderFromSwipe(folder); },
            onMoveBookmark: (folder: string, item: BookmarkItem): void => {
              this.openBookmarkMoveSheet(folder, item);
            },
            onEditBookmark: (folder: string, item: BookmarkItem): void => {
              this.openBookmarkEditSheet(folder, item);
            },
            onDeleteBookmark: (folder: string, item: BookmarkItem): void => {
              this.promptDeleteBookmarkConfirm(folder, item);
            }
          })
        }, (k: string) => `bookmark_page_${k}`)
      }
      .width('100%')
      .layoutWeight(1)
      .id(`bookmark_root_${this.bookmarkRenderEpoch}`);
    }
    .width('100%')
    .height('100%')
    .clip(false)
    .bindSheet($$this.sheetVisible, this.UnifiedSheetBuilder(), {
      detents: [SheetSize.LARGE, SheetSize.MEDIUM],
      dragBar: false,
      showClose: false,
      backgroundColor: $r('sys.color.ohos_id_color_sub_background'),
      keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
      scrollSizeMode: ScrollSizeMode.CONTINUOUS,
      preferType: SheetType.CENTER,
      onWillDismiss: () => {
        this.sheetVisible = false;
        this.anySheetOpen = false;
        this.scheduleSheetModeResetAfterDismiss();
      }
    })
  }
}
