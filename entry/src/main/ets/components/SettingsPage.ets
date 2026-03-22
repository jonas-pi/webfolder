export interface SettingsPageProps {
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
}

@Builder
export function BuildSettingsPage(props: SettingsPageProps) {
  Column() {
    Scroll() {
      Column({ space: 10 }) {
        Row() {
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

        Row() {
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
