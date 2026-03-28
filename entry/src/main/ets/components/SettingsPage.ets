import { listScaleOpacityAppearTransition } from '../utils';
import { curves } from '@kit.ArkUI';

@Component
struct SettingsEntryIcon {
  @Prop iconRes: Resource;
  @Prop titleColor: Resource;
  @Prop epoch: number;
  @Prop iconIndex: number;

  @State private iconScale: number = 0;
  @State private iconRotate: number = 0;
  @State private iconOpacity: number = 0;

  aboutToAppear(): void {
    this.runAnim();
  }

  private runAnim(): void {
    // 先设置明显的初始态，确保每次都能看见动效
    this.iconScale = 0.72;
    this.iconRotate = -24;
    this.iconOpacity = 0;
    // 延后一帧启动，避免初始态与目标态在同一帧被合并导致“看起来不动”
    setTimeout((): void => {
      this.getUIContext().animateTo(
        {
          duration: 260,
          curve: curves.springMotion(0.55, 0.7, 0.65),
          delay: 40 + this.iconIndex * 10
        },
        () => {
          this.iconOpacity = 1;
          this.iconScale = 1;
          this.iconRotate = 0;
        }
      );
    }, 16);
  }

  build() {
    SymbolGlyph(this.iconRes)
      .fontSize(22)
      .fontColor([this.titleColor])
      .margin({ right: 12 })
      .opacity(this.iconOpacity)
      .scale({ x: this.iconScale, y: this.iconScale })
      .rotate({ angle: this.iconRotate });
  }
}

export interface SettingsPageProps {
  iconAnimEpoch: number;
  optionRowMinHeight: number;
  optionRowPadH: number;
  optionRowPadV: number;
  optionCardRadius: number;
  bottomNavBarHeight: number;
  rowClickEffect: ClickEffect;
  contentPrimary: Resource;
  contentSecondary: Resource;
  onOpenSearchSettings: () => void;
  onOpenBackgroundSettings: () => void;
  onOpenGistSync: () => void;
  /** 内嵌云端同步教程（与 docs/云端同步使用说明.md 一致） */
  onOpenCloudSyncGuide: () => void;
  /** 隐私政策：弹窗内可打开线上全文，并再次选择同意 / 不同意 */
  onOpenPrivacyPolicy: () => void;
}

@Builder
export function BuildSettingsPage(props: SettingsPageProps) {
  Column() {
    Scroll() {
      Column({ space: 10 }) {
        Row() {
          // 左侧入口图标：基于 epoch 的可重复动画（确保每次进入“设置”都有动效）
          SettingsEntryIcon({
            iconRes: $r('sys.symbol.wrench_and_screwdriver'),
            titleColor: props.contentPrimary,
            epoch: props.iconAnimEpoch,
            iconIndex: 0
          })
            .id(`settings_icon_search_${props.iconAnimEpoch}`)
          Column() {
            Text('搜索设置')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
            Text('默认搜索引擎、搜索框位置')
              .fontSize(14)
              .fontColor(props.contentSecondary)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(20)
            .fontColor([$r('sys.color.icon_tertiary')])
        }
        .width('100%')
        .height(props.optionRowMinHeight)
        .padding({
          left: props.optionRowPadH,
          right: props.optionRowPadH,
          top: props.optionRowPadV,
          bottom: props.optionRowPadV
        })
        .borderRadius(props.optionCardRadius)
        .backgroundColor($r('app.color.card_background'))
        .border({
          width: 1,
          color: $r('app.color.card_border')
        })
        .alignItems(VerticalAlign.Center)
        .clickEffect(props.rowClickEffect)
        .onClick(() => {
          props.onOpenSearchSettings();
        })
        .transition(listScaleOpacityAppearTransition(0))

        Row() {
          SettingsEntryIcon({
            iconRes: $r('sys.symbol.paintpalette_fill'),
            titleColor: props.contentPrimary,
            epoch: props.iconAnimEpoch,
            iconIndex: 1
          })
            .id(`settings_icon_background_${props.iconAnimEpoch}`)
          Column() {
            Text('设置背景')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
            Text('壁纸、虚化与明暗度')
              .fontSize(14)
              .fontColor(props.contentSecondary)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(20)
            .fontColor([$r('sys.color.icon_tertiary')])
        }
        .width('100%')
        .height(props.optionRowMinHeight)
        .padding({
          left: props.optionRowPadH,
          right: props.optionRowPadH,
          top: props.optionRowPadV,
          bottom: props.optionRowPadV
        })
        .borderRadius(props.optionCardRadius)
        .backgroundColor($r('app.color.card_background'))
        .border({
          width: 1,
          color: $r('app.color.card_border')
        })
        .alignItems(VerticalAlign.Center)
        .clickEffect(props.rowClickEffect)
        .onClick(() => {
          props.onOpenBackgroundSettings();
        })
        .transition(listScaleOpacityAppearTransition(1))

        Row() {
          SettingsEntryIcon({
            iconRes: $r('sys.symbol.arrow_2_circlepath'),
            titleColor: props.contentPrimary,
            epoch: props.iconAnimEpoch,
            iconIndex: 2
          })
            .id(`settings_icon_gist_${props.iconAnimEpoch}`)
          Column() {
            Text('云端同步')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
            Text('GitHub Gist / Gitee 代码片段')
              .fontSize(14)
              .fontColor(props.contentSecondary)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(20)
            .fontColor([$r('sys.color.icon_tertiary')])
        }
        .width('100%')
        .height(props.optionRowMinHeight)
        .padding({
          left: props.optionRowPadH,
          right: props.optionRowPadH,
          top: props.optionRowPadV,
          bottom: props.optionRowPadV
        })
        .borderRadius(props.optionCardRadius)
        .backgroundColor($r('app.color.card_background'))
        .border({
          width: 1,
          color: $r('app.color.card_border')
        })
        .alignItems(VerticalAlign.Center)
        .clickEffect(props.rowClickEffect)
        .onClick(() => {
          props.onOpenGistSync();
        })
        .transition(listScaleOpacityAppearTransition(2))

        Row() {
          SettingsEntryIcon({
            iconRes: $r('sys.symbol.book'),
            titleColor: props.contentPrimary,
            epoch: props.iconAnimEpoch,
            iconIndex: 3
          })
            .id(`settings_icon_sync_guide_${props.iconAnimEpoch}`)
          Column() {
            Text('云端同步使用说明')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
            Text('创建 Gist / Gitee 片段与字段说明')
              .fontSize(14)
              .fontColor(props.contentSecondary)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(20)
            .fontColor([$r('sys.color.icon_tertiary')])
        }
        .width('100%')
        .height(props.optionRowMinHeight)
        .padding({
          left: props.optionRowPadH,
          right: props.optionRowPadH,
          top: props.optionRowPadV,
          bottom: props.optionRowPadV
        })
        .borderRadius(props.optionCardRadius)
        .backgroundColor($r('app.color.card_background'))
        .border({
          width: 1,
          color: $r('app.color.card_border')
        })
        .alignItems(VerticalAlign.Center)
        .clickEffect(props.rowClickEffect)
        .onClick(() => {
          props.onOpenCloudSyncGuide();
        })
        .transition(listScaleOpacityAppearTransition(3))

        Row() {
          SettingsEntryIcon({
            iconRes: $r('sys.symbol.doc_plaintext'),
            titleColor: props.contentPrimary,
            epoch: props.iconAnimEpoch,
            iconIndex: 4
          })
            .id(`settings_icon_privacy_${props.iconAnimEpoch}`)
          Column() {
            Text('隐私政策')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
            Text($r('app.string.settings_privacy_policy_subtitle'))
              .fontSize(14)
              .fontColor(props.contentSecondary)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(20)
            .fontColor([$r('sys.color.icon_tertiary')])
        }
        .width('100%')
        .height(props.optionRowMinHeight)
        .padding({
          left: props.optionRowPadH,
          right: props.optionRowPadH,
          top: props.optionRowPadV,
          bottom: props.optionRowPadV
        })
        .borderRadius(props.optionCardRadius)
        .backgroundColor($r('app.color.card_background'))
        .border({
          width: 1,
          color: $r('app.color.card_border')
        })
        .alignItems(VerticalAlign.Center)
        .clickEffect(props.rowClickEffect)
        .onClick(() => {
          props.onOpenPrivacyPolicy();
        })
        .transition(listScaleOpacityAppearTransition(4))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 0, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
  .width('100%')
  .height('100%')
  .padding({ bottom: props.bottomNavBarHeight + 32 })
  .transition(
    TransitionEffect.translate({ x: -24 })
      .animation({ duration: 200, curve: Curve.FastOutSlowIn })
      .combine(TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.FastOutSlowIn }))
  )
}
