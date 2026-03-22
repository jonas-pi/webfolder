import { common } from '@kit.AbilityKit';
import vibrator from '@ohos.vibrator';
import { authentication } from '@kit.AccountKit';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import { AccountAuthResult, SettingsCache, SearchEngineItem } from '../model';
import {
  OPTION_CARD_RADIUS_VP, OPTION_ROW_MIN_HEIGHT_VP, OPTION_ROW_PAD_H_VP, OPTION_ROW_PAD_V_VP,
  OPTION_SLIDER_CARD_PAD_VP, BOTTOM_NAV_BAR_HEIGHT_VP, ACCOUNT_LOGIN_CARD_AVATAR_VP,
  ACCOUNT_LOGIN_CARD_RADIUS_VP, TOAST_DURATION_SHORT_MS, TOAST_DURATION_LONG_MS,
  SHEET_NONE, SHEET_BACKGROUND, SHEET_ACCOUNT, SHEET_SEARCH_SETTINGS, SHEET_MODE_RESET_DELAY_MS,
  DEFAULT_BACKGROUND_BLUR, DEFAULT_BACKGROUND_BRIGHTNESS, TITLE_CONTENT_GAP_VP
} from '../constants/AppLayout';
import { SEARCH_ENGINES } from '../constants/SearchEngines';
import { buildSettingsCache, applySettingsCache, saveSettingsCache, loadSettingsCache } from '../services';
import { copyByFd as fsCopyByFd, normalizePickerUriToPath as fsNormalizePickerUriToPath } from '../services';
import { inferBackgroundFileSuffix } from '../utils';
import {
  BuildBackgroundSettingsSheet, BuildAccountLoginSheet, BuildSearchSettingsSheet,
  BuildSheetFallbackClose, resolveSheetRoute,
  SHEET_ROUTE_BACKGROUND, SHEET_ROUTE_ACCOUNT, SHEET_ROUTE_SEARCH_SETTINGS, SHEET_ROUTE_FALLBACK_CLOSE
} from './sheets';
import { BuildSettingsPage } from './SettingsPage';

// ── 设置 Tab：账号 / 背景 / 搜索配置 + 持久化 ────────────────────────────────
@Component
export struct SettingsTabComp {
  // 与 Index.ets 的共享状态（@Provide ↔ @Consume 双向绑定）
  @Consume('anySheetOpen') anySheetOpen: boolean;
  @Consume('bgPreviewActive') bgPreviewActive: boolean;
  @Consume('bgPath') backgroundImagePath: string;
  @Consume('bgBlur') backgroundBlurLevel: number;
  @Consume('bgBrightness') backgroundBrightnessLevel: number;
  // 搜索设置：发生变化时自动保存（@Watch 捕获来自任何组件的修改）
  @Watch('onSettingsChanged') @Consume('searchEngineIdx') searchEngineIndex: number;
  @Watch('onSettingsChanged') @Consume('searchBoxPos') searchBoxPosition: number;
  @Watch('onBackPressCloseChanged') @Consume('backPressCloseReq') backPressCloseReq: number = 0;

  // 账号状态（仅本 Tab 使用，不需要 @Provide 到外层）
  @State private accountName: string = '';
  @State private accountStatus: string = '';
  @State private accountAvatarUrl: string = '';
  // 本地半模态
  @State private sheetVisible: boolean = false;
  @State private sheetMode: number = SHEET_NONE;
  // 0=无预览，1=正在拖动虚化滑块，2=正在拖动明暗滑块（触发背景透明预览）
  @State private previewingSlider: number = 0;
  private sheetModeResetTimer: number = -1;
  private settingsSavePending: boolean = false;

  private onSettingsChanged(): void { this.saveSettingsToLocal().catch((_e: Object) => {}); }
  private onBackPressCloseChanged(): void { if (this.sheetVisible) { this.closeModalSheet(); } }

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

  // ── 文件路径 ──────────────────────────────────────────────────────────────
  private settingsCachePath(): string {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return `${ctx.filesDir}/settings_cache.json`;
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

  // ── 入口方法（供 SettingsPage 回调） ──────────────────────────────────────
  private openBackgroundSettings(): void { this.openSheet(SHEET_BACKGROUND); }
  private openAccountLoginSheet(): void { this.openSheet(SHEET_ACCOUNT); }
  private openSearchSettingsSheet(): void { this.openSheet(SHEET_SEARCH_SETTINGS); }

  // ── 设置持久化 ─────────────────────────────────────────────────────────────
  private async saveSettingsToLocal(): Promise<void> {
    if (this.settingsSavePending) { return; }
    this.settingsSavePending = true;
    setTimeout((): void => { this.settingsSavePending = false; }, 0);
    const obj: SettingsCache = buildSettingsCache({
      backgroundImagePath: this.backgroundImagePath,
      backgroundBlurLevel: this.backgroundBlurLevel,
      backgroundBrightnessLevel: this.backgroundBrightnessLevel,
      accountStatus: this.accountStatus,
      accountName: this.accountName,
      accountAvatarUrl: this.accountAvatarUrl,
      searchEngineIndex: this.searchEngineIndex,
      searchBoxPosition: this.searchBoxPosition
    });
    saveSettingsCache(this.settingsCachePath(), obj);
  }

  private async loadSettingsFromLocal(): Promise<void> {
    const restored: SettingsCache | null = await loadSettingsCache(this.settingsCachePath());
    if (restored === null) { return; }
    const patch = applySettingsCache(restored, SEARCH_ENGINES.length);
    if (patch.backgroundImagePath !== undefined) { this.backgroundImagePath = patch.backgroundImagePath; }
    if (patch.backgroundBlurLevel !== undefined) { this.backgroundBlurLevel = patch.backgroundBlurLevel; }
    if (patch.backgroundBrightnessLevel !== undefined) { this.backgroundBrightnessLevel = patch.backgroundBrightnessLevel; }
    if (patch.accountStatus !== undefined) { this.accountStatus = patch.accountStatus; }
    if (patch.accountName !== undefined) { this.accountName = patch.accountName; }
    if (patch.accountAvatarUrl !== undefined) { this.accountAvatarUrl = patch.accountAvatarUrl; }
    if (patch.searchEngineIndex !== undefined) { this.searchEngineIndex = patch.searchEngineIndex; }
    if (patch.searchBoxPosition !== undefined) { this.searchBoxPosition = patch.searchBoxPosition; }
  }

  // ── 背景图片 ───────────────────────────────────────────────────────────────
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

  // ── 华为账号 ───────────────────────────────────────────────────────────────
  private async loginWithHuaweiAccount(): Promise<void> {
    try {
      this.lightHaptic();
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const provider: authentication.HuaweiIDProvider = new authentication.HuaweiIDProvider();
      const request: authentication.AuthorizationWithHuaweiIDRequest =
        provider.createAuthorizationWithHuaweiIDRequest();
      request.scopes = ['profile'];
      request.forceAuthorization = false;
      request.state = `${Date.now()}`;
      const controller: authentication.AuthenticationController =
        new authentication.AuthenticationController(ctx);
      const result: AccountAuthResult = await controller.executeRequest(request) as AccountAuthResult;
      const nickName: string = result.data?.nickName ?? '';
      const avatarUri: string = result.data?.avatarUri ?? '';
      if (nickName.length > 0) { this.accountName = nickName; }
      if (avatarUri.length > 0) { this.accountAvatarUrl = avatarUri; }
      this.accountStatus = nickName.length > 0 ? '华为账号已授权' : '已完成授权';
      this.showCapsuleToast('华为账号登录成功');
      await this.saveSettingsToLocal();
      this.closeModalSheet();
    } catch (err) {
      const errText: string = JSON.stringify(err);
      if (this.sheetVisible) { this.sheetMode = SHEET_ACCOUNT; }
      setTimeout((): void => {
        if (errText.includes('1001502003') || errText.includes('Invalid clientId')) {
          this.showCapsuleToast('授权失败：请先在 AppGallery Connect 开通 Account Kit 并配置 clientId', true);
        } else {
          this.showCapsuleToast(`华为账号授权失败: ${errText}`, true);
        }
      }, 80);
    }
  }

  // ── Sheet Builders ─────────────────────────────────────────────────────────
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
    } else if (this.currentSheetRoute() === SHEET_ROUTE_ACCOUNT) {
      BuildAccountLoginSheet({
        accountName: this.accountName,
        accountStatus: this.accountStatus,
        accountAvatarUrl: this.accountAvatarUrl,
        optionRowPadH: OPTION_ROW_PAD_H_VP,
        optionRowPadV: OPTION_ROW_PAD_V_VP,
        optionCardRadius: OPTION_CARD_RADIUS_VP,
        optionRowMinHeight: OPTION_ROW_MIN_HEIGHT_VP,
        navChromeBg: $r('sys.color.ohos_id_color_sub_background'),
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        rowClickEffect: { level: ClickEffectLevel.MIDDLE, scale: 0.95 },
        onBack: (): void => { this.closeModalSheet(); },
        onLogin: (): void => { this.loginWithHuaweiAccount(); }
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

  // ── 生命周期 ───────────────────────────────────────────────────────────────
  aboutToAppear(): void {
    this.loadSettingsFromLocal().catch((_err: Object) => {
      this.showCapsuleToast('设置恢复失败', true);
    });
  }

  // ── build ─────────────────────────────────────────────────────────────────
  build() {
    Column() {
      BuildSettingsPage({
        accountAvatarUrl: this.accountAvatarUrl,
        accountName: this.accountName,
        accountLoginCardAvatar: ACCOUNT_LOGIN_CARD_AVATAR_VP,
        optionRowMinHeight: OPTION_ROW_MIN_HEIGHT_VP,
        optionRowPadH: OPTION_ROW_PAD_H_VP,
        optionRowPadV: OPTION_ROW_PAD_V_VP,
        optionCardRadius: OPTION_CARD_RADIUS_VP,
        bottomNavBarHeight: BOTTOM_NAV_BAR_HEIGHT_VP,
        rowClickEffect: { level: ClickEffectLevel.MIDDLE, scale: 0.95 },
        contentPrimary: $r('sys.color.ohos_id_color_text_primary'),
        contentSecondary: $r('sys.color.ohos_id_color_text_secondary'),
        onOpenAccount: (): void => { this.openAccountLoginSheet(); },
        onOpenSearchSettings: (): void => { this.openSearchSettingsSheet(); },
        onOpenBackgroundSettings: (): void => { this.openBackgroundSettings(); }
      });
    }
    .width('100%')
    .height('100%')
    .padding({ top: TITLE_CONTENT_GAP_VP })
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
