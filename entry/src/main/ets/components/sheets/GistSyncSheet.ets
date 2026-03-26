import { sheetEnterExitTransition } from '../../utils';

export interface GistSyncSheetProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  optionRowPadH: number;
  optionRowPadV: number;
  optionCardRadius: number;
  optionRowMinHeight: number;
  rowClickEffect: ClickEffect;
  githubToken: string;
  gistId: string;
  gistFileName: string;
  syncBusy: boolean;
  autoUploadAfterEdit: boolean;
  autoPullOnTabFocus: boolean;
  onBack: () => void;
  onTokenChange: (v: string) => void;
  onGistIdChange: (v: string) => void;
  onFileNameChange: (v: string) => void;
  onAutoUploadChange: (on: boolean) => void;
  onAutoPullChange: (on: boolean) => void;
  onSaveConfig: () => void;
  onUpload: () => void;
  onDownload: () => void;
}

@Builder
export function BuildGistSyncSheet(props: GistSyncSheetProps) {
  Column() {
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
      .onClick(() => {
        props.onBack();
      })

      Column() {
        Text('云端同步')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
        Text('GitHub Gist · 与 BookmarkHub 扩展共用同一文件')
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
      Column({ space: 14 }) {
        Text('在 GitHub 创建带 gist 权限的 Token，并新建 Secret Gist；文件名须与浏览器扩展设置一致（默认 BookmarkHub）。')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')

        Text('Token')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')
        TextInput({ text: props.githubToken, placeholder: 'ghp_xxxxxxxx' })
          .height(48)
          .fontSize(15)
          .fontColor(props.contentPrimary)
          .type(InputType.Password)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.card_border') })
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .enabled(!props.syncBusy)
          .onChange((v: string) => {
            props.onTokenChange(v);
          })

        Text('Gist ID')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')
        TextInput({ text: props.gistId, placeholder: '32 位十六进制 ID' })
          .height(48)
          .fontSize(15)
          .fontColor(props.contentPrimary)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.card_border') })
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .enabled(!props.syncBusy)
          .onChange((v: string) => {
            props.onGistIdChange(v);
          })

        Text('Gist 内文件名')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')
        TextInput({ text: props.gistFileName, placeholder: 'BookmarkHub' })
          .height(48)
          .fontSize(15)
          .fontColor(props.contentPrimary)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.card_border') })
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .enabled(!props.syncBusy)
          .onChange((v: string) => {
            props.onFileNameChange(v);
          })

        Row() {
          Column() {
            Text('编辑后自动上传')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
            Text('本地书签变更写盘后约 4.5 秒防抖上传到 Gist')
              .fontSize(12)
              .fontColor(props.contentSecondary)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: props.autoUploadAfterEdit })
            .selectedColor($r('sys.color.ohos_id_color_emphasize'))
            .enabled(!props.syncBusy)
            .onChange((on: boolean) => {
              props.onAutoUploadChange(on);
            })
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
        .border({ width: 1, color: $r('app.color.card_border') })
        .alignItems(VerticalAlign.Center)

        Row() {
          Column() {
            Text('切到收藏夹时自动拉取')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
            Text('仅当本地无未上传修改且远端更新时间更新时覆盖；退后台不会定时拉取')
              .fontSize(12)
              .fontColor(props.contentSecondary)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: props.autoPullOnTabFocus })
            .selectedColor($r('sys.color.ohos_id_color_emphasize'))
            .enabled(!props.syncBusy)
            .onChange((on: boolean) => {
              props.onAutoPullChange(on);
            })
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
        .border({ width: 1, color: $r('app.color.card_border') })
        .alignItems(VerticalAlign.Center)

        Button('保存配置到本机')
          .type(ButtonType.Normal)
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor($r('sys.color.ohos_id_color_text_secondary'))
          .borderRadius(12)
          .enabled(!props.syncBusy)
          .clickEffect(props.rowClickEffect)
          .onClick(() => {
            props.onSaveConfig();
          })

        Row({ space: 12 }) {
          Button('上传到 Gist')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
            .borderRadius(12)
            .enabled(!props.syncBusy)
            .clickEffect(props.rowClickEffect)
            .onClick(() => {
              props.onUpload();
            })

          Button('从 Gist 拉取')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_emphasize'))
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('sys.color.ohos_id_color_emphasize') })
            .borderRadius(12)
            .enabled(!props.syncBusy)
            .clickEffect(props.rowClickEffect)
            .onClick(() => {
              props.onDownload();
            })
        }
        .width('100%')

        Text('手动拉取会覆盖本机书签缓存；手动上传会覆盖 Gist 中该文件。自动同步依赖 SyncData 中的时间戳与本地「待上传」标记。')
          .fontSize(12)
          .fontColor(props.contentSecondary)
          .width('100%')
          .margin({ top: 8 })
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
  .transition(sheetEnterExitTransition())
}
