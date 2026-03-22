export interface AccountLoginSheetProps {
  accountName: string;
  accountStatus: string;
  accountAvatarUrl: string;
  optionRowPadH: number;
  optionRowPadV: number;
  optionCardRadius: number;
  optionRowMinHeight: number;
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  rowClickEffect: ClickEffect;
  onBack: () => void;
  onLogin: () => void;
}

@Builder
export function BuildAccountLoginSheet(props: AccountLoginSheetProps) {
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

      Column() {
        Text('华为账号')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
        Text('登录或管理授权')
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

    Scroll() {
      Column({ space: 10 }) {
        if (props.accountName.length > 0) {
          Row() {
            if (props.accountAvatarUrl.length > 0) {
              Image(props.accountAvatarUrl)
                .width(48)
                .height(48)
                .borderRadius(24)
                .objectFit(ImageFit.Cover)
            } else {
              Image($r('app.media.ic_account_default'))
                .width(48)
                .height(48)
                .borderRadius(24)
            }
            Column({ space: 4 }) {
              Text(props.accountName)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(props.contentPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(props.accountStatus.length > 0 ? props.accountStatus : '已登录')
                .fontSize(13)
                .fontColor(props.contentSecondary)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 12 })
          }
          .width('100%')
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
        }

        Row() {
          Image($r('app.media.ic_huawei_logo'))
            .width(40)
            .height(40)
            .objectFit(ImageFit.Contain)
          Column() {
            Text('华为账号登录')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
            Text(props.accountName.length > 0 ? '重新授权或更新账号信息' : '使用华为账号授权登录本应用')
              .fontSize(14)
              .fontColor(props.contentSecondary)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 12 })

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
        .border({
          width: 1,
          color: $r('app.color.card_border')
        })
        .alignItems(VerticalAlign.Center)
        .clickEffect(props.rowClickEffect)
        .onClick(() => {
          props.onLogin();
        })
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
  .backgroundColor(props.navChromeBg)
}
