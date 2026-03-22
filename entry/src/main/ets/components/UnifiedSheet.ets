export interface SheetFallbackProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  onBack: () => void;
}

@Builder
export function BuildSheetFallbackClose(props: SheetFallbackProps) {
  Column() {
    Row() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(22)
          .fontColor([$r('sys.color.icon_secondary')])
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.back_button_bg'))
      .borderRadius(22)
      .clickEffect({ level: ClickEffectLevel.LIGHT })
      .onClick(() => {
        props.onBack();
      })

      Text('返回')
        .fontSize(17)
        .fontColor(props.contentPrimary)
        .margin({ left: 8 })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(props.navChromeBg)
  }
  .width('100%')
  .height('100%')
  .backgroundColor(props.navChromeBg)
}
