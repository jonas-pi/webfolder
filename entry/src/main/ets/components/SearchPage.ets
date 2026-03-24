import { common, Want } from '@kit.AbilityKit';
import vibrator from '@ohos.vibrator';
import { TOAST_DURATION_SHORT_MS } from '../constants/AppLayout';
import { SEARCH_ENGINES } from '../constants/SearchEngines';
import type { SearchEngineItem } from '../model/IndexTypes';
import { listScaleOpacityAppearTransition } from '../utils';

/** 左侧引擎图标热区：圆角与高度一半一致，按压时为椭圆高亮而非矩形水波纹 */
const SEARCH_ENGINE_ICON_TOUCH_W: number = 44;
const SEARCH_ENGINE_ICON_TOUCH_H: number = 48;
const SEARCH_GO_BTN_W: number = 48;
const SEARCH_GO_BTN_H: number = 44;

@Component
export struct SearchPageComp {
  /** 与 Index @State 双向同步；HMOS 禁止 @Prop 传函数，故用 @Link 替代回调 */
  @Link enginePickerOpen: boolean;
  @Link searchQuery: string;
  @Link searchSessionEngineIndex: number;

  @Prop searchBoxAlignment: Alignment = Alignment.TopStart;
  @Prop bottomNavBarHeight: number = 0;

  @State private leftIconPressed: boolean = false;
  @State private rightSearchPressed: boolean = false;
  /** 每次打开引擎下拉时递增，用于强制重建列表节点，确保入场动画每次都触发 */
  @State private pickerAnimEpoch: number = 0;

  private lightHaptic(): void {
    vibrator.startVibration({ type: 'time', duration: 8 }, { id: 0, usage: 'touch' })
      .catch((): void => {});
  }

  private clampSearchEngineIndex(idx: number): number {
    if (idx >= 0 && idx < SEARCH_ENGINES.length) {
      return idx;
    }
    return 0;
  }

  private searchPlaceholderText(): string {
    const i: number = this.clampSearchEngineIndex(this.searchSessionEngineIndex);
    return `${SEARCH_ENGINES[i].name} 搜索`;
  }

  private currentEngineIcon(): Resource {
    const i: number = this.clampSearchEngineIndex(this.searchSessionEngineIndex);
    return SEARCH_ENGINES[i].icon;
  }

  private async openUrlInBrowser(url: string): Promise<void> {
    try {
      this.lightHaptic();
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await ctx.startAbility({ deviceId: '', action: 'ohos.want.action.viewData', uri: url } as Want);
    } catch (err) {
      try {
        this.getUIContext().getPromptAction().showToast({
          message: `打开失败: ${JSON.stringify(err)}`, duration: TOAST_DURATION_SHORT_MS
        });
      } catch (_e) {}
    }
  }

  /** 与 Stack.alignContent 对应：在 Scroll 内用 Column 垂直对齐搜索块 */
  private searchBlockVerticalJustify(): FlexAlign {
    if (this.searchBoxAlignment === Alignment.Center) {
      return FlexAlign.Center;
    }
    if (this.searchBoxAlignment === Alignment.BottomStart) {
      return FlexAlign.End;
    }
    return FlexAlign.Start;
  }

  private performWebSearch(): void {
    const raw: string = this.searchQuery.trim();
    if (raw.length === 0) {
      try {
        this.getUIContext().getPromptAction().showToast({
          message: '请输入搜索关键词', duration: TOAST_DURATION_SHORT_MS
        });
      } catch (_e) {}
      return;
    }
    const i: number = this.clampSearchEngineIndex(this.searchSessionEngineIndex);
    this.openUrlInBrowser(`${SEARCH_ENGINES[i].prefix}${encodeURIComponent(raw)}`).catch((_e: Object) => {});
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 透明全屏层：仅用于「点空白处关闭」，不用半透明灰底，避免壁纸/背景被压成一块灰色
      if (this.enginePickerOpen) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Transparent)
          .hitTestBehavior(HitTestMode.Default)
          .onClick((): void => {
            this.enginePickerOpen = false;
          })
      }

      // 与「我的」页一致：Scroll + Spring；垂直位置由原 searchBoxAlignment 映射到内层 Column.justifyContent
      Scroll() {
        Column() {
          Column({ space: 0 }) {
        Row() {
          Row() {
            Image(this.currentEngineIcon())
              .width(24)
              .height(24)
              .objectFit(ImageFit.Contain)
              .draggable(false)
          }
          .width(SEARCH_ENGINE_ICON_TOUCH_W)
          .height(SEARCH_ENGINE_ICON_TOUCH_H)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .flexShrink(0)
          .draggable(false)
          .borderRadius(SEARCH_ENGINE_ICON_TOUCH_H / 2)
          .backgroundColor(this.leftIconPressed ? 0x18000000 : Color.Transparent)
          .animation({ duration: 90, curve: Curve.FastOutSlowIn })
          .onTouch((e: TouchEvent) => {
            if (e.type === TouchType.Down) {
              this.leftIconPressed = true;
            } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
              this.leftIconPressed = false;
            }
          })
          .onClick((): void => {
            this.lightHaptic();
            if (!this.enginePickerOpen) {
              this.pickerAnimEpoch = this.pickerAnimEpoch + 1;
              this.enginePickerOpen = true;
            } else {
              this.enginePickerOpen = false;
            }
          })

          TextInput({ placeholder: this.searchPlaceholderText(), text: this.searchQuery })
            .layoutWeight(1)
            .flexShrink(1)
            .constraintSize({ minWidth: 0 })
            .height(44)
            .draggable(false)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .fontSize(15)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .placeholderColor($r('sys.color.ohos_id_color_text_secondary'))
            .enterKeyType(EnterKeyType.Search)
            .onChange((value: string) => {
              this.searchQuery = value;
            })
            .onSubmit((): void => {
              this.performWebSearch();
            })

          Row() {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontSize(20)
              .fontColor([$r('sys.color.ohos_id_color_emphasize')])
              .draggable(false)
          }
          .width(SEARCH_GO_BTN_W)
          .height(SEARCH_GO_BTN_H)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .flexShrink(0)
          .draggable(false)
          .borderRadius(SEARCH_GO_BTN_H / 2)
          .backgroundColor(this.rightSearchPressed ? 0x18000000 : Color.Transparent)
          .animation({ duration: 90, curve: Curve.FastOutSlowIn })
          .onTouch((e: TouchEvent) => {
            if (e.type === TouchType.Down) {
              this.rightSearchPressed = true;
            } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
              this.rightSearchPressed = false;
            }
          })
          .onClick((): void => {
            this.lightHaptic();
            this.performWebSearch();
          })
        }
        .width('100%')
        .height(50)
        .padding({ left: 2, right: 2, top: 2, bottom: 2 })
        .borderRadius(999)
        .backgroundColor($r('app.color.card_background'))
        .border({
          width: 1,
          color: $r('app.color.card_border')
        })
        .alignItems(VerticalAlign.Center)
        .draggable(false)

        if (this.enginePickerOpen) {
          Column({ space: 0 }) {
            Scroll() {
              Column({ space: 0 }) {
                ForEach(SEARCH_ENGINES, (item: SearchEngineItem, idx: number) => {
                  Column({ space: 0 }) {
                    Row({ space: 10 }) {
                      Image(item.icon)
                        .width(22)
                        .height(22)
                        .objectFit(ImageFit.Contain)
                        .draggable(false)
                      Text(this.searchSessionEngineIndex === idx ? `${item.name}（当前）` : item.name)
                        .fontSize(16)
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.Start)
                    }
                    .width('100%')
                    .height(48)
                    .padding({ left: 12, right: 12 })
                    .alignItems(VerticalAlign.Center)
                    .onClick((): void => {
                      this.lightHaptic();
                      this.searchSessionEngineIndex = idx;
                      this.enginePickerOpen = false;
                    })
                    if (idx < SEARCH_ENGINES.length - 1) {
                      Divider()
                        .strokeWidth(0.5)
                        .color($r('app.color.card_border'))
                        .margin({ left: 12, right: 12 })
                    }
                  }
                  .width('100%')
                  // 引擎列表逐个错峰入场：淡入 + 缩放（spring）
                  .transition(listScaleOpacityAppearTransition(idx))
                }, (item: SearchEngineItem, idx: number) => `se_pick_${this.pickerAnimEpoch}_${idx}_${item.name}`)
              }
              .width('100%')
            }
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .constraintSize({ maxHeight: 320 })
            .width('100%')
          }
          .width('100%')
          .margin({ top: 8 })
          .padding({ top: 4, bottom: 4 })
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(16)
          .border({ width: 1, color: $r('app.color.card_border') })
          .clip(true)
          .shadow(ShadowStyle.OUTER_DEFAULT_SM)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .constraintSize({ minHeight: '100%' })
      .justifyContent(this.searchBlockVerticalJustify())
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .zIndex(1)
    }
    // 顶栏在 Index 的 TabContent 内单独渲染，此处仅保留底部与输入区留白
    .width('100%')
    .height('100%')
    .padding({ top: 0, bottom: this.bottomNavBarHeight + 32 })
    .transition(
      TransitionEffect.translate({ x: -24 })
        .animation({ duration: 200, curve: Curve.FastOutSlowIn })
        .combine(TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.FastOutSlowIn }))
    )
  }
}
