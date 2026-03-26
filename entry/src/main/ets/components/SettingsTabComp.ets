import { common, Want } from '@kit.AbilityKit';
import vibrator from '@ohos.vibrator';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import { SettingsCache } from '../model';
import type { GistSyncSettings } from '../model/GistSyncSettings';
import {
  OPTION_CARD_RADIUS_VP, OPTION_ROW_MIN_HEIGHT_VP, OPTION_ROW_PAD_H_VP, OPTION_ROW_PAD_V_VP,
  OPTION_SLIDER_CARD_PAD_VP, BOTTOM_NAV_BAR_HEIGHT_VP, TOAST_DURATION_SHORT_MS, TOAST_DURATION_LONG_MS,
  SHEET_NONE, SHEET_BACKGROUND, SHEET_SEARCH_SETTINGS, SHEET_GIST_SYNC, SHEET_MODE_RESET_DELAY_MS,
  DEFAULT_BACKGROUND_BLUR, DEFAULT_BACKGROUND_BRIGHTNESS
} from '../constants/AppLayout';
import { SEARCH_ENGINES } from '../constants/SearchEngines';
import {
  buildSettingsCache, applySettingsCache, saveSettingsCache, loadSettingsCache,
  loadBookmarkSyncData, saveBookmarkSyncData,
  defaultGistSyncSettings, saveGistSyncSettings, loadGistSyncSettings,
  githubFetchGistRaw, extractGistFileText, githubPatchGistFiles,
  setPrivacyPolicyAccepted, PRIVACY_POLICY_PAGE_URL
} from '../services';
import { bookmarkPayloadFromParsedJson, flatItemsToSyncData } from '../utils/BookmarkHubSyncConverter';
import { copyByFd as fsCopyByFd, normalizePickerUriToPath as fsNormalizePickerUriToPath } from '../services';
import { inferBackgroundFileSuffix } from '../utils';
import {
  BuildBackgroundSettingsSheet, BuildSearchSettingsSheet, BuildGistSyncSheet,
  BuildSheetFallbackClose, resolveSheetRoute,
  SHEET_ROUTE_BACKGROUND, SHEET_ROUTE_SEARCH_SETTINGS, SHEET_ROUTE_GIST_SYNC, SHEET_ROUTE_FALLBACK_CLOSE
} from './sheets';
import { BuildSettingsPage } from './SettingsPage';
import { PrivacyConsentDialog } from './PrivacyConsentDialog';

// ── 设置 Tab：背景 / 搜索配置 + 持久化 ───────────────────────────────────────
@Component
export struct SettingsTabComp {
  @Consume('bookmarkDataReloadReq') bookmarkDataReloadReq: number = 0;
  @Consume('anySheetOpen') anySheetOpen: boolean;
  @Consume('bgPreviewActive') bgPreviewActive: boolean;
  @Consume('bgPath') backgroundImagePath: string;
  @Consume('bgBlur') backgroundBlurLevel: number;
  @Consume('bgBrightness') backgroundBrightnessLevel: number;
  @Watch('onSettingsChanged') @Consume('searchEngineIdx') searchEngineIndex: number;
  @Watch('onSettingsChanged') @Consume('searchBoxPos') searchBoxPosition: number;
  @Consume('settingsTabAnimEpoch') settingsTabAnimEpoch: number;
  @Watch('onBackPressCloseChanged') @Consume('backPressCloseReq') backPressCloseReq: number = 0;

  @State private sheetVisible: boolean = false;
  @State private sheetMode: number = SHEET_NONE;
  @State private previewingSlider: number = 0;
  /** Gist 同步页：表单与网络进行中状态 */
  @State private gistGithubToken: string = '';
  @State private gistIdInput: string = '';
  @State private gistFileNameInput: string = '';
  @State private gistSyncBusy: boolean = false;
  @State private gistAutoUploadAfterEdit: boolean = false;
  @State private gistAutoPullOnTabFocus: boolean = false;
  private sheetModeResetTimer: number = -1;
  private settingsSavePending: boolean = false;

  /**
   * 「我的 → 隐私政策」：与首次启动同结构的 CustomDialog。
   * 仅点「不同意」会清除同意标记并退出；系统返回 / cancel 仅关闭弹窗，不撤销同意。
   */
  private privacySettingsDialogController: CustomDialogController = new CustomDialogController({
    builder: PrivacyConsentDialog({
      settingsReconfirm: true,
      onAgree: (): void => {
        // 弹窗内在「同意」时已 close；用户本已同意过，无需重复写 preferences
      },
      onDisagree: (): void => {
        void this.revokePrivacyConsentAndExit();
      },
      onOpenPrivacy: (): void => {
        void this.openPrivacyPolicyInBrowser();
      }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true,
    cancel: (): void => {
      this.privacySettingsDialogController.close();
    }
  });

  private onSettingsChanged(): void { this.saveSettingsToLocal().catch((_e: Object) => {}); }
  private onBackPressCloseChanged(): void { if (this.sheetVisible) { this.closeModalSheet(); } }

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

  private settingsCachePath(): string {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return `${ctx.filesDir}/settings_cache.json`;
  }

  private gistSettingsCachePath(): string {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return `${ctx.filesDir}/gist_sync_settings.json`;
  }

  private bookmarkCachePath(): string {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return `${ctx.filesDir}/bookmarks_cache.json`;
  }

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

  private openBackgroundSettings(): void { this.openSheet(SHEET_BACKGROUND); }
  private openSearchSettingsSheet(): void { this.openSheet(SHEET_SEARCH_SETTINGS); }

  private openGistSyncSheet(): void {
    this.loadGistFormFromDisk().catch((_e: Object) => {});
    this.openSheet(SHEET_GIST_SYNC);
  }

  /** 打开隐私确认弹窗（可点链接在浏览器查看 GitHub Pages 全文） */
  private openPrivacyPolicyEntry(): void {
    this.lightHaptic();
    this.privacySettingsDialogController.open();
  }

  private async openPrivacyPolicyInBrowser(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await ctx.startAbility({
        deviceId: '',
        action: 'ohos.want.action.viewData',
        uri: PRIVACY_POLICY_PAGE_URL
      } as Want);
    } catch (_e) {
    }
  }

  /**
   * 用户选择「不同意」或对话框 cancel：清除本地同意标记（下次启动再次强制弹窗），并立即退出应用。
   */
  private async revokePrivacyConsentAndExit(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await setPrivacyPolicyAccepted(ctx, false);
    } catch (_e) {
    }
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      ctx.terminateSelf();
    } catch (_e) {
    }
  }

  /** 打开同步页前把磁盘上的 Token 等读入输入框 */
  private async loadGistFormFromDisk(): Promise<void> {
    const s: GistSyncSettings = await loadGistSyncSettings(this.gistSettingsCachePath());
    this.gistGithubToken = s.githubToken;
    this.gistIdInput = s.gistId;
    this.gistFileNameInput = s.gistFileName.length > 0 ? s.gistFileName : defaultGistSyncSettings().gistFileName;
    this.gistAutoUploadAfterEdit = s.autoUploadAfterEdit;
    this.gistAutoPullOnTabFocus = s.autoPullOnTabFocus;
  }

  private persistGistFormToDisk(): void {
    const obj: GistSyncSettings = {
      githubToken: this.gistGithubToken.trim(),
      gistId: this.gistIdInput.trim(),
      gistFileName: this.gistFileNameInput.trim().length > 0 ? this.gistFileNameInput.trim() :
        defaultGistSyncSettings().gistFileName,
      autoUploadAfterEdit: this.gistAutoUploadAfterEdit,
      autoPullOnTabFocus: this.gistAutoPullOnTabFocus
    };
    saveGistSyncSettings(this.gistSettingsCachePath(), obj);
  }

  private validateGistFormForSync(): string | null {
    const token: string = this.gistGithubToken.trim();
    const gid: string = this.gistIdInput.trim();
    const fn: string = this.gistFileNameInput.trim().length > 0 ? this.gistFileNameInput.trim() :
      defaultGistSyncSettings().gistFileName;
    if (token.length === 0) {
      return '请填写 GitHub Token';
    }
    if (gid.length === 0) {
      return '请填写 Gist ID';
    }
    if (fn.length === 0) {
      return '请填写 Gist 文件名';
    }
    return null;
  }

  private onSaveGistConfigOnly(): void {
    this.lightHaptic();
    this.persistGistFormToDisk();
    this.showCapsuleToast('已保存 Gist 配置');
  }

  private async onUploadBookmarksToGist(): Promise<void> {
    const err: string | null = this.validateGistFormForSync();
    if (err !== null) {
      this.showCapsuleToast(err);
      return;
    }
    this.persistGistFormToDisk();
    const token: string = this.gistGithubToken.trim();
    const gid: string = this.gistIdInput.trim();
    const fn: string = this.gistFileNameInput.trim().length > 0 ? this.gistFileNameInput.trim() :
      defaultGistSyncSettings().gistFileName;
    this.gistSyncBusy = true;
    try {
      let sync = await loadBookmarkSyncData(this.bookmarkCachePath());
      if (sync === null) {
        sync = flatItemsToSyncData([]);
      }
      sync.createDate = Date.now();
      sync.browser = 'HarmonyOS/HM';
      const body: string = JSON.stringify(sync);
      await githubPatchGistFiles(token, gid, fn, body);
      saveBookmarkSyncData(this.bookmarkCachePath(), sync);
      this.showCapsuleToast('已上传到 Gist');
    } catch (e) {
      this.showCapsuleToast(`上传失败: ${JSON.stringify(e)}`, true);
    } finally {
      this.gistSyncBusy = false;
    }
  }

  private async onDownloadBookmarksFromGist(): Promise<void> {
    const err: string | null = this.validateGistFormForSync();
    if (err !== null) {
      this.showCapsuleToast(err);
      return;
    }
    this.persistGistFormToDisk();
    const token: string = this.gistGithubToken.trim();
    const gid: string = this.gistIdInput.trim();
    const fn: string = this.gistFileNameInput.trim().length > 0 ? this.gistFileNameInput.trim() :
      defaultGistSyncSettings().gistFileName;
    this.gistSyncBusy = true;
    try {
      const gistJson: string = await githubFetchGistRaw(token, gid);
      const fileText: string = await extractGistFileText(token, gistJson, fn);
      const parsed: object = JSON.parse(fileText) as object;
      const sync = bookmarkPayloadFromParsedJson(parsed);
      if (sync === null) {
        this.showCapsuleToast('Gist 文件内容不是有效的书签数据', true);
        return;
      }
      saveBookmarkSyncData(this.bookmarkCachePath(), sync);
      this.bookmarkDataReloadReq = this.bookmarkDataReloadReq + 1;
      this.showCapsuleToast('已从 Gist 拉取并覆盖本机书签');
      this.closeModalSheet();
    } catch (e) {
      this.showCapsuleToast(`拉取失败: ${JSON.stringify(e)}`, true);
    } finally {
      this.gistSyncBusy = false;
    }
  }

  private async saveSettingsToLocal(): Promise<void> {
    if (this.settingsSavePending) { return; }
    this.settingsSavePending = true;
    setTimeout((): void => { this.settingsSavePending = false; }, 0);
    const obj: SettingsCache = buildSettingsCache({
      backgroundImagePath: this.backgroundImagePath,
      backgroundBlurLevel: this.backgroundBlurLevel,
      backgroundBrightnessLevel: this.backgroundBrightnessLevel,
      searchEngineIndex: this.searchEngineIndex,
      searchBoxPosition: this.searchBoxPosition
    });
    saveSettingsCache(this.settingsCachePath(), obj);
  }

  /**
   * 读本地 settings_cache；无文件或 JSON 损坏时静默使用当前默认状态，不向用户弹 Toast
   * （避免 Tab 重建、读盘竞态或缓存异常时每次进「我的」都误报「设置恢复失败」）。
   */
  private async loadSettingsFromLocal(): Promise<void> {
    try {
      const restored: SettingsCache | null = await loadSettingsCache(this.settingsCachePath());
      if (restored === null) {
        return;
      }
      const patch = applySettingsCache(restored, SEARCH_ENGINES.length);
      if (patch.backgroundImagePath !== undefined) {
        this.backgroundImagePath = patch.backgroundImagePath;
      }
      if (patch.backgroundBlurLevel !== undefined) {
        this.backgroundBlurLevel = patch.backgroundBlurLevel;
      }
      if (patch.backgroundBrightnessLevel !== undefined) {
        this.backgroundBrightnessLevel = patch.backgroundBrightnessLevel;
      }
      if (patch.searchEngineIndex !== undefined) {
        this.searchEngineIndex = patch.searchEngineIndex;
      }
      if (patch.searchBoxPosition !== undefined) {
        this.searchBoxPosition = patch.searchBoxPosition;
      }
    } catch (_e) {
      // 静默：损坏或空文件等不应打断使用
    }
  }

  private async importBackgroundImage(): Promise<void> {
    try {
      this.lightHaptic();
      const imagePicker: picker.DocumentViewPicker = new picker.DocumentViewPicker();
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['Image|.jpg,.jpeg,.png,.webp,.gif'];
      const uris: Array<string> = await imagePicker.select(options);
      if (uris.length === 0) { this.showCapsuleToast('未选择背景图片'); return; }
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const selectedUri: string = uris[0];
      const normalizedPath: string = fsNormalizePickerUriToPath(selectedUri);
      const ext: string = inferBackgroundFileSuffix(selectedUri, normalizedPath);
      const destPath: string = `${ctx.filesDir}/custom_background_${Date.now()}${ext}`;
      try {
        await fs.copyFile(selectedUri, destPath);
      } catch (_) {
        try {
          await fs.copyFile(normalizedPath, destPath);
        } catch (_) {
          try { fsCopyByFd(selectedUri, destPath); } catch (_) { fsCopyByFd(normalizedPath, destPath); }
        }
      }
      this.backgroundImagePath = `file://${destPath}`;
      await this.saveSettingsToLocal();
      this.showCapsuleToast('背景图片已更新');
    } catch (err) {
      this.showCapsuleToast(`背景图片设置失败: ${JSON.stringify(err)}`, true);
    }
  }

  private async restoreDefaultBackground(): Promise<void> {
    try {
      this.lightHaptic();
      this.backgroundImagePath = '';
      this.backgroundBlurLevel = DEFAULT_BACKGROUND_BLUR;
      this.backgroundBrightnessLevel = DEFAULT_BACKGROUND_BRIGHTNESS;
      await this.saveSettingsToLocal();
      this.showCapsuleToast('已恢复默认背景');
    } catch (err) {
      this.showCapsuleToast(`恢复默认失败: ${JSON.stringify(err)}`, true);
    }
  }

  private currentSheetRoute(): number {
    return resolveSheetRoute(this.sheetMode, this.sheetVisible);
  }

  @Builder
  private UnifiedSheetBuilder() {
    if (this.currentSheetRoute() === SHEET_ROUTE_BACKGROUND) {
      BuildBackgroundSettingsSheet({
        navChromeBg: $r('sys.color.ohos_id_color_sub_background'),
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        optionRowPadH: OPTION_ROW_PAD_H_VP,
        optionRowPadV: OPTION_ROW_PAD_V_VP,
        optionSliderPadV: OPTION_SLIDER_CARD_PAD_VP,
        optionCardRadius: OPTION_CARD_RADIUS_VP,
        optionRowMinHeight: OPTION_ROW_MIN_HEIGHT_VP,
        rowClickEffect: { level: ClickEffectLevel.MIDDLE, scale: 0.95 },
        backgroundImagePath: this.backgroundImagePath,
        backgroundBlurLevel: this.backgroundBlurLevel,
        backgroundBrightnessLevel: this.backgroundBrightnessLevel,
        onBack: (): void => { this.closeModalSheet(); },
        onImportBg: (): void => { this.importBackgroundImage(); },
        onRestoreDefault: (): void => { this.restoreDefaultBackground().catch((_e: Object) => {}); },
        previewingSlider: this.previewingSlider,
        onBlurChanged: (value: number): void => { this.backgroundBlurLevel = Math.floor(value); },
        onBlurTouch: (event: TouchEvent): void => {
          if (event.type === TouchType.Down) {
            this.lightHaptic();
            this.previewingSlider = 1;
            this.bgPreviewActive = true;
          }
          if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.previewingSlider = 0;
            this.bgPreviewActive = false;
            this.saveSettingsToLocal().catch((_e: Object) => {});
          }
        },
        onBrightnessChanged: (value: number): void => { this.backgroundBrightnessLevel = Math.floor(value); },
        onBrightnessTouch: (event: TouchEvent): void => {
          if (event.type === TouchType.Down) {
            this.lightHaptic();
            this.previewingSlider = 2;
            this.bgPreviewActive = true;
          }
          if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.previewingSlider = 0;
            this.bgPreviewActive = false;
            this.saveSettingsToLocal().catch((_e: Object) => {});
          }
        }
      });
    } else if (this.currentSheetRoute() === SHEET_ROUTE_GIST_SYNC) {
      BuildGistSyncSheet({
        navChromeBg: $r('sys.color.ohos_id_color_sub_background'),
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        optionRowPadH: OPTION_ROW_PAD_H_VP,
        optionRowPadV: OPTION_ROW_PAD_V_VP,
        optionCardRadius: OPTION_CARD_RADIUS_VP,
        optionRowMinHeight: OPTION_ROW_MIN_HEIGHT_VP,
        rowClickEffect: { level: ClickEffectLevel.MIDDLE, scale: 0.95 },
        githubToken: this.gistGithubToken,
        gistId: this.gistIdInput,
        gistFileName: this.gistFileNameInput,
        syncBusy: this.gistSyncBusy,
        autoUploadAfterEdit: this.gistAutoUploadAfterEdit,
        autoPullOnTabFocus: this.gistAutoPullOnTabFocus,
        onBack: (): void => { this.closeModalSheet(); },
        onTokenChange: (v: string): void => { this.gistGithubToken = v; },
        onGistIdChange: (v: string): void => { this.gistIdInput = v; },
        onFileNameChange: (v: string): void => { this.gistFileNameInput = v; },
        onAutoUploadChange: (on: boolean): void => {
          this.lightHaptic();
          this.gistAutoUploadAfterEdit = on;
          this.persistGistFormToDisk();
        },
        onAutoPullChange: (on: boolean): void => {
          this.lightHaptic();
          this.gistAutoPullOnTabFocus = on;
          this.persistGistFormToDisk();
        },
        onSaveConfig: (): void => { this.onSaveGistConfigOnly(); },
        onUpload: (): void => { this.onUploadBookmarksToGist().catch((_e: Object) => {}); },
        onDownload: (): void => { this.onDownloadBookmarksFromGist().catch((_e: Object) => {}); }
      });
    } else if (this.currentSheetRoute() === SHEET_ROUTE_SEARCH_SETTINGS) {
      BuildSearchSettingsSheet({
        navChromeBg: $r('sys.color.ohos_id_color_sub_background'),
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        optionRowPadH: OPTION_ROW_PAD_H_VP,
        optionRowPadV: OPTION_ROW_PAD_V_VP,
        optionCardRadius: OPTION_CARD_RADIUS_VP,
        optionRowMinHeight: OPTION_ROW_MIN_HEIGHT_VP,
        rowClickEffect: { level: ClickEffectLevel.MIDDLE, scale: 0.95 },
        searchEngines: SEARCH_ENGINES,
        searchEngineIndex: this.searchEngineIndex,
        searchBoxPosition: this.searchBoxPosition,
        onBack: (): void => { this.closeModalSheet(); },
        onSelectEngine: (idx: number): void => {
          this.lightHaptic();
          this.searchEngineIndex = idx;
          this.saveSettingsToLocal().catch((_e: Object) => {});
        },
        onSelectSearchBoxPos: (pos: number): void => {
          this.lightHaptic();
          this.searchBoxPosition = pos;
          this.saveSettingsToLocal().catch((_e: Object) => {});
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

  aboutToAppear(): void {
    this.loadSettingsFromLocal().catch((_err: Object) => {});
  }

  build() {
    Column() {
      BuildSettingsPage({
        iconAnimEpoch: this.settingsTabAnimEpoch,
        optionRowMinHeight: OPTION_ROW_MIN_HEIGHT_VP,
        optionRowPadH: OPTION_ROW_PAD_H_VP,
        optionRowPadV: OPTION_ROW_PAD_V_VP,
        optionCardRadius: OPTION_CARD_RADIUS_VP,
        bottomNavBarHeight: BOTTOM_NAV_BAR_HEIGHT_VP,
        rowClickEffect: { level: ClickEffectLevel.MIDDLE, scale: 0.95 },
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        onOpenSearchSettings: (): void => { this.openSearchSettingsSheet(); },
        onOpenBackgroundSettings: (): void => { this.openBackgroundSettings(); },
        onOpenGistSync: (): void => { this.openGistSyncSheet(); },
        onOpenPrivacyPolicy: (): void => { this.openPrivacyPolicyEntry(); }
      });
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.sheetVisible, this.UnifiedSheetBuilder(), {
      detents: [SheetSize.LARGE, SheetSize.MEDIUM],
      dragBar: false,
      showClose: false,
      backgroundColor: this.previewingSlider > 0
        ? Color.Transparent
        : $r('sys.color.ohos_id_color_sub_background'),
      maskColor: this.previewingSlider > 0 ? Color.Transparent : 'rgba(0,0,0,0.3)',
      keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
      scrollSizeMode: ScrollSizeMode.CONTINUOUS,
      preferType: SheetType.CENTER,
      onWillDismiss: () => {
        this.previewingSlider = 0;
        this.bgPreviewActive = false;
        this.sheetVisible = false;
        this.anySheetOpen = false;
        this.scheduleSheetModeResetAfterDismiss();
      }
    })
  }
}
