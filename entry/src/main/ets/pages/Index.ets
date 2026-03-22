import { common } from '@kit.AbilityKit';
import { curves, window } from '@kit.ArkUI';
import vibrator from '@ohos.vibrator';
import {
  NAV_TAB_ICON_ANIM_MS, TAB_SWIPE_DURATION_MS, TITLE_BAR_HEIGHT_VP, TITLE_BAR_FONT_SIZE,
  BOTTOM_NAV_BAR_HEIGHT_VP, BOTTOM_INDICATOR_SAFE_VP, DEFAULT_BACKGROUND_BLUR,
  DEFAULT_BACKGROUND_BRIGHTNESS
} from '../constants/AppLayout';
import { backgroundMaskColorFromBrightness, isBackgroundGifPath } from '../utils';
import { BookmarkTabComp } from '../components/BookmarkTabComp';
import { SettingsTabComp } from '../components/SettingsTabComp';
import { SearchPageComp } from '../components/SearchPage';

// ── 应用根入口：负责导航框架 + 壁纸渲染 + 状态 @Provide ──────────────────────
@Entry
@Component
struct Index {
  // ── 导航 ──────────────────────────────────────────────────────────────────
  @State private currentTab: number = 0;
  private swiperController: SwiperController = new SwiperController();

  // ── 壁纸状态（Index build() 使用 + SettingsTabComp @Consume 修改） ────────
  // @Provide 本身已具备响应式能力，不需要叠加 @State
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
  /**
   * 搜索页当前使用的引擎（仅本次会话，点左侧图标在菜单里切换；不写回设置）。
   * 默认引擎变更时通过 onSearchEngineDefaultChanged 与 searchEngineIndex 对齐。
   */
  @State private searchSessionEngineIndex: number = 0;

  // ── 触发器：Index 顶栏 → BookmarkTabComp 动作 ─────────────────────────────
  @Provide('openNewBookmarkReq') openNewBookmarkReq: number = 0;
  @Provide('importBookmarksReq') importBookmarksReq: number = 0;
  @Provide('backPressCloseReq') backPressCloseReq: number = 0;

  // ── 搜索页局部状态（仅 SearchPage 使用，无需下放） ───────────────────────
  @State private searchQuery: string = '';
  /** 搜索引擎下拉列表展开（供系统返回键 / 切 Tab 关闭） */
  @State private searchEnginePickerOpen: boolean = false;
  // ── 状态栏占位高度（vp），来自窗口避让区，随设备/旋转/折叠更新 ─────────────
  @State private statusBarHeight: number = 38;
  /** 用于注销窗口事件，避免重复订阅 */
  private mainWindowRef: window.Window | null = null;
  private windowSizeChangeHandler: (() => void) | null = null;
  // ── 加号按钮菜单展开时的旋转角度 ─────────────────────────────────────────
  @State private plusRotation: number = 0;

  // ── 工具方法 ───────────────────────────────────────────────────────────────
  private lightHaptic(): void {
    vibrator.startVibration({ type: 'time', duration: 10 }, { id: 0, usage: 'touch' })
      .catch((): void => {});
  }

  private rowClickEffect(): ClickEffect {
    return { level: ClickEffectLevel.MIDDLE, scale: 0.95 };
  }

  private iconClickEffect(): ClickEffect {
    return { level: ClickEffectLevel.LIGHT, scale: 0.95 };
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

  private mainPageTitle(): string {
    return (['收藏夹', '搜索', '我的'])[this.currentTab];
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

  // ── @Builder：顶栏 ─────────────────────────────────────────────────────────
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

  @Builder
  private MainHeader() {
    Row() {
      Text(this.mainPageTitle())
        .fontSize(TITLE_BAR_FONT_SIZE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
      if (this.currentTab === 0) {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(24)
          .fontColor([$r('sys.color.icon_secondary')])
          .rotate({ angle: this.plusRotation })
          .animation({ duration: 280, curve: Curve.FastOutSlowIn })
          .clickEffect(this.iconClickEffect())
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) { this.plusRotation = 135; }
          })
          .bindMenu(this.BookmarkAddMenuBuilder, {
            // 点击菜单项时 onClick 已重置旋转；点击外部关闭时此处兜底
            // 用 duration:0 让按钮在菜单消失后立即归位，避免迟滞残影
            onDisappear: (): void => {
              animateTo({ duration: 0 }, () => { this.plusRotation = 0; });
            }
          })
      }
    }
    .width('100%')
    .height(TITLE_BAR_HEIGHT_VP)
    .padding({ left: 16, right: 16, top: 0, bottom: 0 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.navChromeBackgroundColor())
    // 与下方 Swiper.clip(false) + 书签 List 负 margin 叠加时，后绘制的 Swiper 会盖住标题；抬高 zIndex 保证标题区不被覆盖
    .zIndex(1)
  }

  @Builder
  private BottomNavTab(label: string, tabId: number, symbol: Resource) {
    Column({ space: 3 }) {
      SymbolGlyph(symbol)
        .fontSize(22)
        .fontColor([this.currentTab === tabId ? $r('sys.color.ohos_id_color_emphasize') :
          $r('sys.color.icon_tertiary')])
        .translate({ y: this.currentTab === tabId ? -3 : 0 })
        .animation({ duration: NAV_TAB_ICON_ANIM_MS, curve: Curve.FastOutSlowIn })
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentTab === tabId ? $r('sys.color.ohos_id_color_emphasize') :
          $r('sys.color.icon_tertiary'))
        .translate({ y: this.currentTab === tabId ? -1 : 0 })
        .animation({ duration: NAV_TAB_ICON_ANIM_MS, curve: Curve.FastOutSlowIn })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 6, bottom: 6 })
    .layoutWeight(1)
    .clickEffect(this.rowClickEffect())
    .onClick(() => {
      if (this.currentTab !== tabId) {
        this.swiperController.changeIndex(tabId, false);
      } else {
        this.lightHaptic();
      }
    })
  }

  @Builder
  private SearchPage() {
    SearchPageComp({
      enginePickerOpen: $searchEnginePickerOpen,
      searchQuery: $searchQuery,
      searchSessionEngineIndex: $searchSessionEngineIndex,
      searchBoxAlignment: this.searchBoxStackAlignment(),
      bottomNavBarHeight: BOTTOM_NAV_BAR_HEIGHT_VP
    });
  }

  // ── 生命周期 ───────────────────────────────────────────────────────────────
  aboutToAppear(): void {
    this.searchSessionEngineIndex = this.searchEngineIndex;
    this.swiperController.changeIndex(0, false);
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
    Column() {
      // 内容区（壁纸 + 顶栏 + Swiper）
      Stack({ alignContent: Alignment.TopStart }) {
        // 壁纸层
        if (this.backgroundImagePath.length > 0) {
          Image(this.backgroundImagePath)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            // GIF：syncLoad 利于动图解码播放；静态图也可用
            .syncLoad(isBackgroundGifPath(this.backgroundImagePath))
            .blur(this.backgroundBlurLevel)
        }
        // 亮度遮罩
        if (this.backgroundImagePath.length > 0) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(backgroundMaskColorFromBrightness(this.backgroundBrightnessLevel))
        }

        // 主界面：状态栏带与标题栏同色（不显示壁纸）；下方为标题 + Swiper
        Column() {
          // 系统状态栏占位区：与标题栏同色，随系统深浅色切换（壁纸不延伸到此）
          Column()
            .width('100%')
            .height(this.statusBarHeight)
            .backgroundColor(this.navChromeBackgroundColor())

          Column() {
            this.MainHeader()

            // 标题与 Swiper 之间不再占位：书签列表用 margin+padding 抵消，滑动时可滚入该带；
            // 搜索/设置 Tab 在各自根节点补回 TITLE_CONTENT_GAP_VP

            Swiper(this.swiperController) {
              BookmarkTabComp()
              Column() { this.SearchPage() }
                .width('100%')
                .height('100%')
              SettingsTabComp()
            }
            .width('100%')
            .layoutWeight(1)
            // 降低预缓存页数，减轻 Swiper 对子页实例的保留，避免收藏夹 Tab 与数据不同步
            .cachedCount(1)
            .indicator(false)
            .loop(false)
            .duration(TAB_SWIPE_DURATION_MS)
            .curve(curves.springMotion())
            .disableSwipe(this.anySheetOpen)
            .onChange((index: number) => {
              if (index !== this.currentTab) { this.lightHaptic(); }
              if (index !== 1) {
                this.searchEnginePickerOpen = false;
              }
              this.currentTab = index;
            })
            .clip(false)
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        // 背景预览时淡出主界面，让壁纸效果完整呈现给用户
        // bindSheet 渲染在窗口层，不受此 opacity 影响，设置面板仍然可见
        .opacity(this.bgPreviewActive ? 0 : 1)
        .animation({ duration: 180, curve: Curve.FastOutSlowIn })
      }
      .layoutWeight(1)
      .width('100%')
      .foregroundBlurStyle(
        (this.anySheetOpen && !this.bgPreviewActive) ? BlurStyle.Thin : BlurStyle.NONE,
        { colorMode: ThemeColorMode.SYSTEM, adaptiveColor: AdaptiveColor.DEFAULT, scale: 0.3 }
      )

      // 底部导航栏（总高 = 内容区 + 小白条安全避让）
      Row() {
        this.BottomNavTab('收藏夹', 0, $r('sys.symbol.bookmark'));
        this.BottomNavTab('搜索', 1, $r('sys.symbol.magnifyingglass'));
        this.BottomNavTab('我的', 2, $r('sys.symbol.person'));
      }
      .width('100%')
      .height(BOTTOM_NAV_BAR_HEIGHT_VP + BOTTOM_INDICATOR_SAFE_VP)
      .alignItems(VerticalAlign.Top)
      .padding({ left: 8, right: 8, top: 0, bottom: BOTTOM_INDICATOR_SAFE_VP })
      .backgroundColor(this.navChromeBackgroundColor())
      .opacity(this.bgPreviewActive ? 0 : 1)
      .animation({ duration: 180, curve: Curve.FastOutSlowIn })
    }
    .height('100%')
    .width('100%')
    // 仅扩展底部：避免与「状态栏占位 Column + getWindowAvoidArea」叠用导致顶部留白过大
    // 顶部避让完全由 statusBarHeight（TYPE_SYSTEM → vp）控制，随分辨率/比例一致
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
