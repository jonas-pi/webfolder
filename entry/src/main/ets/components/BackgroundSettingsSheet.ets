export interface BackgroundSettingsSheetProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  optionRowPadH: number;
  optionRowPadV: number;
  optionSliderPadV: number;
  optionCardRadius: number;
  optionRowMinHeight: number;
  rowClickEffect: ClickEffect;
  backgroundImagePath: string;
  backgroundBlurLevel: number;
  backgroundBrightnessLevel: number;
  /** 0=正常，1=正在拖虚化滑块，2=正在拖明暗滑块 */
  previewingSlider: number;
  onBack: () => void;
  onImportBg: () => void;
  onRestoreDefault: () => void;
  onBlurChanged: (v: number) => void;
  onBlurTouch: (e: TouchEvent) => void;
  onBrightnessChanged: (v: number) => void;
  onBrightnessTouch: (e: TouchEvent) => void;
}

/** 预览时元素淡出的统一动画参数 */
const PREVIEW_ANIM: AnimateParam = { duration: 180, curve: Curve.FastOutSlowIn };

@Builder
export function BuildBackgroundSettingsSheet(props: BackgroundSettingsSheetProps) {
  // Stack：底层是面板背景色，顶层是内容，两者可独立控制 opacity
  Stack({ alignContent: Alignment.TopStart }) {

    // ── 底层背景色（拖动时整体淡出，露出壁纸） ────────────────────────────────
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(props.navChromeBg)
      .opacity(props.previewingSlider > 0 ? 0 : 1)
      .animation(PREVIEW_ANIM)

    // ── 顶层：所有 UI 内容 ─────────────────────────────────────────────────
    Column() {

      // 标题栏：拖动时隐藏
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(22)
            .fontColor([$r('sys.color.icon_secondary')])
        }
        .width(40)
        .height(40)
        .backgroundColor($r('app.color.back_button_bg'))
        .clickEffect({ level: ClickEffectLevel.LIGHT })
        .onClick(() => { props.onBack(); })

        Column() {
          Text('设置背景')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(props.contentPrimary)
          Text('壁纸、虚化与明暗度')
            .fontSize(14)
            .fontColor(props.contentSecondary)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 8, right: 16 })
      }
      .width('100%')
      .padding({ left: 15, right: 15, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(props.navChromeBg)
      .opacity(props.previewingSlider > 0 ? 0 : 1)
      .animation(PREVIEW_ANIM)

      Scroll() {
        Column({ space: 10 }) {

          // "更换背景图片"：拖动时隐藏
          Row() {
            Column() {
              Text('更换背景图片')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(props.contentPrimary)
              Text('从相册或文件中选择（支持 JPG/PNG/WebP/GIF）')
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
          .constraintSize({ minHeight: props.optionRowMinHeight })
          .padding({
            left: props.optionRowPadH,
            right: props.optionRowPadH,
            top: props.optionRowPadV,
            bottom: props.optionRowPadV
          })
          .borderRadius(props.optionCardRadius)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.card_border') })
          .alignItems(VerticalAlign.Center)
          .clickEffect(props.rowClickEffect)
          .onClick(() => { props.onImportBg(); })
          .opacity(props.previewingSlider > 0 ? 0 : 1)
          .animation(PREVIEW_ANIM)

          // "恢复默认"：拖动时隐藏
          Row() {
            Column() {
              Text('恢复默认')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(props.contentPrimary)
              Text('清除壁纸并重置虚化与明暗度')
                .fontSize(14)
                .fontColor(props.contentSecondary)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
              .fontSize(20)
              .fontColor([$r('sys.color.icon_tertiary')])
          }
          .width('100%')
          .constraintSize({ minHeight: props.optionRowMinHeight })
          .padding({
            left: props.optionRowPadH,
            right: props.optionRowPadH,
            top: props.optionRowPadV,
            bottom: props.optionRowPadV
          })
          .borderRadius(props.optionCardRadius)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.card_border') })
          .alignItems(VerticalAlign.Center)
          .clickEffect(props.rowClickEffect)
          .onClick(() => { props.onRestoreDefault(); })
          .opacity(props.previewingSlider > 0 ? 0 : 1)
          .animation(PREVIEW_ANIM)

          if (props.backgroundImagePath.length > 0) {

            // 虚化滑块：拖明暗度时隐藏，其余时候可见
            Column() {
              Row() {
                Text('背景虚化强度')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(props.contentPrimary)
                  .layoutWeight(1)
                Text(`${props.backgroundBlurLevel}`)
                  .fontSize(14)
                  .fontColor(props.contentSecondary)
              }
              .width('100%')
              .margin({ bottom: 8 })

              Slider({ value: props.backgroundBlurLevel, min: 0, max: 60, step: 1, style: SliderStyle.OutSet })
                .width('100%')
                .onChange((value: number) => { props.onBlurChanged(value); })
                .onTouch((event: TouchEvent) => { props.onBlurTouch(event); })
            }
            .width('100%')
            .padding({
              left: props.optionRowPadH,
              right: props.optionRowPadH,
              top: props.optionSliderPadV,
              bottom: props.optionSliderPadV
            })
            .borderRadius(props.optionCardRadius)
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('app.color.card_border') })
            .opacity(props.previewingSlider === 2 ? 0 : 1)
            .animation(PREVIEW_ANIM)

            // 明暗度滑块：拖虚化时隐藏，其余时候可见
            Column() {
              Row() {
                Text('背景明暗度')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(props.contentPrimary)
                  .layoutWeight(1)
                Text(`${props.backgroundBrightnessLevel}`)
                  .fontSize(14)
                  .fontColor(props.contentSecondary)
              }
              .width('100%')
              .margin({ bottom: 8 })

              Slider({ value: props.backgroundBrightnessLevel, min: 0, max: 100, step: 1, style: SliderStyle.OutSet })
                .width('100%')
                .onChange((value: number) => { props.onBrightnessChanged(value); })
                .onTouch((event: TouchEvent) => { props.onBrightnessTouch(event); })
            }
            .width('100%')
            .padding({
              left: props.optionRowPadH,
              right: props.optionRowPadH,
              top: props.optionSliderPadV,
              bottom: props.optionSliderPadV
            })
            .borderRadius(props.optionCardRadius)
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('app.color.card_border') })
            .opacity(props.previewingSlider === 1 ? 0 : 1)
            .animation(PREVIEW_ANIM)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 32 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')

  }
  .width('100%')
  .height('100%')
}
