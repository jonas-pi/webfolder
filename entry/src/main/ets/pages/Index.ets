import { common, Want } from '@kit.AbilityKit';
// BarMode / BarPosition / TabsController 由 ArkUI 声明式框架注入为全局符号，勿从 @kit.ArkUI 导入（与 SDK 6.x Kit 导出表一致）
import { curves, window } from '@kit.ArkUI';
import vibrator from '@ohos.vibrator';
import {
  NAV_TAB_ICON_ANIM_MS, TAB_SWIPE_DURATION_MS, TITLE_CONTENT_GAP_VP,
  BOTTOM_NAV_BAR_HEIGHT_VP, BOTTOM_INDICATOR_SAFE_VP, DEFAULT_BACKGROUND_BLUR,
  DEFAULT_BACKGROUND_BRIGHTNESS
} from '../constants/AppLayout';
import { backgroundMaskColorFromBrightness, isBackgroundGifPath } from '../utils';
import { BookmarkTabComp } from '../components/BookmarkTabComp';
import { SettingsTabComp } from '../components/SettingsTabComp';
import { SearchPageComp } from '../components/SearchPage';
import { MainTabTitleBar } from '../components/chrome/MainTabTitleBar';
import { PrivacyConsentDialog } from '../components/PrivacyConsentDialog';
import {
  hasAcceptedPrivacyPolicy,
  setPrivacyPolicyAccepted,
  PRIVACY_POLICY_PAGE_URL
} from '../services';

/**
 * 应用根入口：壁纸 + 主框架。
 * 主框架对齐 ClashBox：Tabs + TabContent（顶栏标题在各自 Tab 内容区内），
 * 状态栏占位顶 padding，底栏由 Tabs 的 tabBar 承担。
 */
@Entry
@Component
struct Index {
  // ── 导航（与 Tabs index 绑定） ────────────────────────────────────────────
  @State private currentTab: number = 0;
  private tabsController: TabsController = new TabsController();

  // ── 壁纸状态（Index build() 使用 + SettingsTabComp @Consume 修改） ────────
  @Provide('bgPath') backgroundImagePath: string = '';
  @Provide('bgBlur') backgroundBlurLevel: number = DEFAULT_BACKGROUND_BLUR;
  @Provide('bgBrightness') backgroundBrightnessLevel: number = DEFAULT_BACKGROUND_BRIGHTNESS;

  // ── 跨 Tab 共享：Sheet 开关 + 搜索设置（两个 Tab 都用） ────────────────────
  @Provide('anySheetOpen') anySheetOpen: boolean = false;
  /** 正在拖动背景滑块预览中；true 时临时关闭前景毛玻璃，让壁纸效果清晰可见 */
  @Provide('bgPreviewActive') bgPreviewActive: boolean = false;
  /** 设置里保存的「默认搜索引擎」索引（持久化） */
  @Watch('onSearchEngineDefaultChanged') @Provide('searchEngineIdx') searchEngineIndex: number = 0;
  @Provide('searchBoxPos') searchBoxPosition: number = 0;
  /** 每次进入「我的」页时递增，用于触发设置页图标转场重播 */
  @Provide('settingsTabAnimEpoch') settingsTabAnimEpoch: number = 0;
  /**
   * 搜索页当前使用的引擎（仅本次会话，点左侧图标在菜单里切换；不写回设置）。
   * 默认引擎变更时通过 onSearchEngineDefaultChanged 与 searchEngineIndex 对齐。
   */
  @State private searchSessionEngineIndex: number = 0;

  // ── 触发器：收藏夹 Tab 顶栏 → BookmarkTabComp 动作 ───────────────────────
  @Provide('openNewBookmarkReq') openNewBookmarkReq: number = 0;
  @Provide('importBookmarksReq') importBookmarksReq: number = 0;
  @Provide('backPressCloseReq') backPressCloseReq: number = 0;
  /** 递增后收藏夹 Tab 从磁盘重新加载书签（Gist 拉取完成等） */
  @Provide('bookmarkDataReloadReq') bookmarkDataReloadReq: number = 0;
  /** 从其它 Tab 切回「收藏夹」时递增，触发自动拉取（若已开启） */
  @Provide('bookmarkGistAutoPullReq') bookmarkGistAutoPullReq: number = 0;

  // ── 搜索页局部状态（仅 SearchPage 使用，无需下放） ───────────────────────
  @State private searchQuery: string = '';
  /** 搜索引擎下拉列表展开（供系统返回键 / 切 Tab 关闭） */
  @State private searchEnginePickerOpen: boolean = false;
  // ── 状态栏占位高度（vp），来自窗口避让区，随设备/旋转/折叠更新 ─────────────
  @State private statusBarHeight: number = 38;
  /** 用于注销窗口事件，避免重复订阅 */
  private mainWindowRef: window.Window | null = null;
  private windowSizeChangeHandler: (() => void) | null = null;

  // ── 首次启动隐私确认（未同意前禁止实质使用，返回键等同不同意） ───────────
  @State private privacyGateResolved: boolean = false;
  @State private privacyConsented: boolean = false;
  /** autoCancel: false + cancel 回调，避免绕过确认；样式随 sys.color 深浅色自适应 */
  private privacyDialogController: CustomDialogController = new CustomDialogController({
    builder: PrivacyConsentDialog({
      settingsReconfirm: false,
      onAgree: (): void => {
        void this.handlePrivacyAgree();
      },
      onDisagree: (): void => {
        this.handlePrivacyDisagree();
      },
      onOpenPrivacy: (): void => {
        void this.openPrivacyPolicyPage();
      }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true,
    cancel: (): void => {
      this.handlePrivacyDisagree();
    }
  });

  // ── 工具方法 ───────────────────────────────────────────────────────────────
  private lightHaptic(): void {
    vibrator.startVibration({ type: 'time', duration: 10 }, { id: 0, usage: 'touch' })
      .catch((): void => {});
  }

  private rowClickEffect(): ClickEffect {
    return { level: ClickEffectLevel.MIDDLE, scale: 0.95 };
  }

  private navChromeBackgroundColor(): ResourceColor {
    return $r('sys.color.ohos_id_color_sub_background');
  }

  /**
   * 从窗口 TYPE_SYSTEM 避让区刷新状态栏顶部占位（vp）。
   * 全屏布局下勿与 expandSafeArea(SafeAreaEdge.TOP) 叠用，否则易重复留白。
   */
  private applyStatusBarInsetFromWindow(win: window.Window): void {
    try {
      const area: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const hPx: number = area.topRect.height;
      if (hPx <= 0) {
        return;
      }
      const heightVp: number = px2vp(hPx);
      if (heightVp > 0) {
        this.statusBarHeight = heightVp;
      }
    } catch (_e) {}
  }

  // ── 搜索相关 ───────────────────────────────────────────────────────────────
  /** 默认搜索引擎变化时，搜索页会话引擎与之对齐（导入设置、在「我的」里改默认等） */
  private onSearchEngineDefaultChanged(): void {
    this.searchSessionEngineIndex = this.searchEngineIndex;
  }

  private searchBoxStackAlignment(): Alignment {
    if (this.searchBoxPosition === 1) { return Alignment.Center; }
    if (this.searchBoxPosition === 2) { return Alignment.BottomStart; }
    return Alignment.TopStart;
  }

  /** 底栏单项外观（点击由 Tabs 统一处理，此处仅展示） */
  @Builder
  private BottomNavTab(label: string, tabId: number, symbol: Resource) {
    Column({ space: 3 }) {
      SymbolGlyph(symbol)
        .fontSize(22)
        .fontColor([this.currentTab === tabId ? $r('sys.color.ohos_id_color_emphasize') :
          $r('sys.color.icon_tertiary')])
        .translate({ y: this.currentTab === tabId ? -3 : 0 })
        .animation({ duration: NAV_TAB_ICON_ANIM_MS, curve: curves.springMotion(0.5, 0.7, 0.6) })
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentTab === tabId ? $r('sys.color.ohos_id_color_emphasize') :
          $r('sys.color.icon_tertiary'))
        .translate({ y: this.currentTab === tabId ? -1 : 0 })
        .animation({ duration: NAV_TAB_ICON_ANIM_MS, curve: curves.springMotion(0.5, 0.7, 0.6) })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 6, bottom: 6 })
    .layoutWeight(1)
    .clickEffect(this.rowClickEffect())
  }

  @Builder
  private SearchPage() {
    SearchPageComp({
      enginePickerOpen: $searchEnginePickerOpen,
      searchQuery: $searchQuery,
      searchSessionEngineIndex: $searchSessionEngineIndex,
      searchBoxAlignment: this.searchBoxStackAlignment(),
      bottomNavBarHeight: BOTTOM_NAV_BAR_HEIGHT_VP
    })
      .layoutWeight(1)
      .width('100%');
  }

  /** 异步读取是否已同意隐私；未完成前 UI 仅显示加载占位，避免未授权可操作主界面 */
  private async resolvePrivacyGate(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const ok: boolean = await hasAcceptedPrivacyPolicy(ctx);
      this.privacyConsented = ok;
      this.privacyGateResolved = true;
      if (!ok) {
        this.privacyDialogController.open();
      }
    } catch (_e) {
      this.privacyConsented = false;
      this.privacyGateResolved = true;
      this.privacyDialogController.open();
    }
  }

  private async handlePrivacyAgree(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await setPrivacyPolicyAccepted(ctx, true);
      this.privacyConsented = true;
    } catch (_e) {
      // 写入失败时不视为已同意，用户可重试「同意」
    }
  }

  private handlePrivacyDisagree(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      ctx.terminateSelf();
    } catch (_e) {
    }
  }

  private async openPrivacyPolicyPage(): Promise<void> {
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

  // ── 生命周期 ───────────────────────────────────────────────────────────────
  aboutToAppear(): void {
    this.searchSessionEngineIndex = this.searchEngineIndex;
    this.currentTab = 0;
    this.searchEnginePickerOpen = false;
    // SDK 6.x：changeIndex 仅接收目标索引；无第二参数控制动画（需关动画可短时设 Tabs.animationDuration(0)）
    this.tabsController.changeIndex(0);
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      window.getLastWindow(ctx).then((win: window.Window) => {
        this.mainWindowRef = win;
        this.applyStatusBarInsetFromWindow(win);
        const handler = (): void => {
          this.applyStatusBarInsetFromWindow(win);
        };
        this.windowSizeChangeHandler = handler;
        win.on('windowSizeChange', handler);
      }).catch((): void => {});
    } catch (_e) {}
    void this.resolvePrivacyGate();
  }

  aboutToDisappear(): void {
    if (this.mainWindowRef !== null && this.windowSizeChangeHandler !== null) {
      try {
        this.mainWindowRef.off('windowSizeChange', this.windowSizeChangeHandler);
      } catch (_e) {}
      this.mainWindowRef = null;
      this.windowSizeChangeHandler = null;
    }
  }

  onBackPress(): boolean {
    if (this.privacyGateResolved && !this.privacyConsented) {
      this.handlePrivacyDisagree();
      return true;
    }
    if (this.searchEnginePickerOpen) {
      this.searchEnginePickerOpen = false;
      return true;
    }
    if (this.anySheetOpen) {
      this.backPressCloseReq++;
      return true;
    }
    return false;
  }

  // ── build ─────────────────────────────────────────────────────────────────
  build() {
    Stack() {
      if (!this.privacyGateResolved) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color($r('sys.color.ohos_id_color_emphasize'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('sys.color.comp_background_primary'))
      } else {
        Column() {
          Stack({ alignContent: Alignment.TopStart }) {
        if (this.backgroundImagePath.length > 0) {
          Image(this.backgroundImagePath)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .syncLoad(isBackgroundGifPath(this.backgroundImagePath))
            .blur(this.backgroundBlurLevel)
        }
        if (this.backgroundImagePath.length > 0) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(backgroundMaskColorFromBrightness(this.backgroundBrightnessLevel))
        }

        Column() {
          Column()
            .width('100%')
            .height(this.statusBarHeight)
            .backgroundColor(this.navChromeBackgroundColor())

          Tabs({
            barPosition: BarPosition.End,
            index: this.currentTab,
            controller: this.tabsController
          }) {
            TabContent() {
              BookmarkTabComp()
            }
            .tabBar(this.BottomNavTab('收藏夹', 0, $r('sys.symbol.bookmark')))

            TabContent() {
              Column({ space: TITLE_CONTENT_GAP_VP }) {
                MainTabTitleBar({ title: '搜索' })
                this.SearchPage()
              }
              .width('100%')
              .height('100%');
            }
            .tabBar(this.BottomNavTab('搜索', 1, $r('sys.symbol.magnifyingglass')))

            TabContent() {
              Column({ space: TITLE_CONTENT_GAP_VP }) {
                MainTabTitleBar({ title: '我的' })
                SettingsTabComp()
                  .layoutWeight(1)
                  .width('100%')
              }
              .width('100%')
              .height('100%');
            }
            .tabBar(this.BottomNavTab('我的', 2, $r('sys.symbol.person')))
          }
          .width('100%')
          .layoutWeight(1)
          .barOverlap(false)
          .barMode(BarMode.Fixed)
          .scrollable(!this.anySheetOpen)
          .animationDuration(TAB_SWIPE_DURATION_MS)
          .barHeight(BOTTOM_NAV_BAR_HEIGHT_VP + BOTTOM_INDICATOR_SAFE_VP)
          .backgroundColor(Color.Transparent)
          .barBackgroundColor(this.navChromeBackgroundColor())
          .onChange((index: number) => {
            const prevTab: number = this.currentTab;
            if (index !== prevTab) {
              this.lightHaptic();
            }
            if (index !== 1) {
              this.searchEnginePickerOpen = false;
            }
            if (index === 2 && prevTab !== 2) {
              this.settingsTabAnimEpoch = this.settingsTabAnimEpoch + 1;
            }
            if (index === 0 && prevTab !== 0) {
              this.bookmarkGistAutoPullReq = this.bookmarkGistAutoPullReq + 1;
            }
            this.currentTab = index;
          })
        }
        .width('100%')
        .layoutWeight(1)
        .opacity(this.bgPreviewActive ? 0 : 1)
        .animation({ duration: 180, curve: Curve.FastOutSlowIn })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .height('100%')
    .width('100%')
      }
    }
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
