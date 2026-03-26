/**
 * 隐私确认弹窗：首次启动强制确认，或「我的」内再次阅读并确认。
 * 使用 @CustomDialog + sys.color，随系统深浅色自适应；次操作 + 主操作按钮布局。
 */
@CustomDialog
export struct PrivacyConsentDialog {
  /** 由框架注入，用于关闭对话框 */
  controller?: CustomDialogController;
  /**
   * false：首次启动文案；true：设置内再次确认（说明撤销同意与退出后果）。
   */
  settingsReconfirm: boolean = false;
  /** 用户点击「同意」后的回调（首次启动时用于持久化；设置内可为空） */
  onAgree: () => void = (): void => {};
  /** 不同意或系统取消：首次启动为退出；设置内为清除同意标记并退出 */
  onDisagree: () => void = (): void => {};
  /** 在系统浏览器中打开线上隐私政策全文 */
  onOpenPrivacy: () => void = (): void => {};

  build() {
    Column({ space: 20 }) {
      Text(this.settingsReconfirm ? $r('app.string.privacy_reconfirm_title') :
        $r('app.string.privacy_dialog_title'))
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .width('100%')
        .textAlign(TextAlign.Start)

      Text() {
        Span(this.settingsReconfirm ? $r('app.string.privacy_reconfirm_lead') :
          $r('app.string.privacy_dialog_lead'))
        Span($r('app.string.privacy_dialog_link'))
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .fontWeight(FontWeight.Medium)
          .onClick((): void => {
            this.onOpenPrivacy();
          })
        Span(this.settingsReconfirm ? $r('app.string.privacy_reconfirm_tail') :
          $r('app.string.privacy_dialog_tail'))
      }
      .fontSize(15)
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .lineHeight(23)
      .width('100%')

      Row({ space: 12 }) {
        Button($r('app.string.privacy_disagree'), { type: ButtonType.Capsule, stateEffect: true })
          .layoutWeight(1)
          .height(40)
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .onClick((): void => {
            this.onDisagree();
          })

        Button($r('app.string.privacy_agree'), { type: ButtonType.Capsule, stateEffect: true })
          .layoutWeight(1)
          .height(40)
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
          .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
          .onClick((): void => {
            this.controller?.close();
            this.onAgree();
          })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .padding({ left: 24, right: 24, top: 24, bottom: 20 })
    .width('100%')
    .constraintSize({ minWidth: 280, maxWidth: 400 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(24)
  }
}
