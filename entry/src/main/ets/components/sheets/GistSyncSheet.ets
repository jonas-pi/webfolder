import { sheetEnterExitTransition } from '../../utils';
import { GIST_PROVIDER_GITHUB, GIST_PROVIDER_GITEE } from '../../model/GistSyncSettings';

export interface GistSyncSheetProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  optionRowPadH: number;
  optionRowPadV: number;
  optionCardRadius: number;
  optionRowMinHeight: number;
  rowClickEffect: ClickEffect;
  gistProvider: string;
  githubToken: string;
  githubGistId: string;
  githubFileName: string;
  giteeToken: string;
  giteeGistId: string;
  giteeFileName: string;
  syncBusy: boolean;
  autoUploadAfterEdit: boolean;
  autoPullOnTabFocus: boolean;
  onBack: () => void;
  onProviderChange: (provider: string) => void;
  onGithubTokenChange: (v: string) => void;
  onGithubGistIdChange: (v: string) => void;
  onGithubFileNameChange: (v: string) => void;
  onGiteeTokenChange: (v: string) => void;
  onGiteeGistIdChange: (v: string) => void;
  onGiteeFileNameChange: (v: string) => void;
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
        Text('GitHub Gist 或 Gitee 代码片段 · 载荷与 BookmarkHub 一致')
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
        Text('同步源')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')
        Row({ space: 10 }) {
          Button('GitHub Gist')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(props.gistProvider === GIST_PROVIDER_GITHUB ? Color.White : props.contentPrimary)
            .backgroundColor(props.gistProvider === GIST_PROVIDER_GITHUB ?
              $r('sys.color.ohos_id_color_emphasize') : $r('app.color.card_background'))
            .border({
              width: 1,
              color: props.gistProvider === GIST_PROVIDER_GITHUB ?
                $r('sys.color.ohos_id_color_emphasize') : $r('app.color.card_border')
            })
            .borderRadius(12)
            .enabled(!props.syncBusy)
            .onClick(() => {
              props.onProviderChange(GIST_PROVIDER_GITHUB);
            })
          Button('Gitee 片段')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(props.gistProvider === GIST_PROVIDER_GITEE ? Color.White : props.contentPrimary)
            .backgroundColor(props.gistProvider === GIST_PROVIDER_GITEE ?
              $r('sys.color.ohos_id_color_emphasize') : $r('app.color.card_background'))
            .border({
              width: 1,
              color: props.gistProvider === GIST_PROVIDER_GITEE ?
                $r('sys.color.ohos_id_color_emphasize') : $r('app.color.card_border')
            })
            .borderRadius(12)
            .enabled(!props.syncBusy)
            .onClick(() => {
              props.onProviderChange(GIST_PROVIDER_GITEE);
            })
        }
        .width('100%')
        Text('GitHub 与 Gitee 的令牌、片段 ID、文件名分别保存；切换同步源仅切换当前上传/拉取使用的云端。')
          .fontSize(12)
          .fontColor(props.contentSecondary)
          .width('100%')
          .lineHeight(18)

        if (props.gistProvider === GIST_PROVIDER_GITEE) {
          Text('在 Gitee 个人设置中创建私人令牌（需代码片段相关权限），新建「私密」代码片段；文件名建议与其它端一致（默认 BookmarkHub）。')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
        } else {
          Text('在 GitHub 创建带 gist 权限的 Token，并新建 Secret Gist；文件名须与浏览器扩展设置一致（默认 BookmarkHub）。')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
        }

        Text('访问令牌')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')
        TextInput({
          text: props.gistProvider === GIST_PROVIDER_GITEE ? props.giteeToken : props.githubToken,
          placeholder: props.gistProvider === GIST_PROVIDER_GITEE ? 'Gitee 私人令牌' : 'ghp_xxxxxxxx'
        })
          .height(48)
          .fontSize(15)
          .fontColor(props.contentPrimary)
          // 不用 Password：否则会强制系统「安全键盘」，不便粘贴 PAT；令牌仍仅存本机 prefs
          .type(InputType.Normal)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.card_border') })
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .enabled(!props.syncBusy)
          .onChange((v: string) => {
            if (props.gistProvider === GIST_PROVIDER_GITEE) {
              props.onGiteeTokenChange(v);
            } else {
              props.onGithubTokenChange(v);
            }
          })

        Text('片段 ID')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')
        TextInput({
          text: props.gistProvider === GIST_PROVIDER_GITEE ? props.giteeGistId : props.githubGistId,
          placeholder: '在片段 URL 中的 ID'
        })
          .height(48)
          .fontSize(15)
          .fontColor(props.contentPrimary)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.card_border') })
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .enabled(!props.syncBusy)
          .onChange((v: string) => {
            if (props.gistProvider === GIST_PROVIDER_GITEE) {
              props.onGiteeGistIdChange(v);
            } else {
              props.onGithubGistIdChange(v);
            }
          })

        Text('片段内文件名')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')
        TextInput({
          text: props.gistProvider === GIST_PROVIDER_GITEE ? props.giteeFileName : props.githubFileName,
          placeholder: 'BookmarkHub'
        })
          .height(48)
          .fontSize(15)
          .fontColor(props.contentPrimary)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.card_border') })
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .enabled(!props.syncBusy)
          .onChange((v: string) => {
            if (props.gistProvider === GIST_PROVIDER_GITEE) {
              props.onGiteeFileNameChange(v);
            } else {
              props.onGithubFileNameChange(v);
            }
          })

        Row() {
          Column() {
            Text('编辑后自动上传')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
            Text('本地书签变更写盘后约 4.5 秒防抖上传到云端')
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
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('sys.color.ohos_id_color_emphasize') })
          .borderRadius(12)
          .enabled(!props.syncBusy)
          .clickEffect(props.rowClickEffect)
          .onClick(() => {
            props.onSaveConfig();
          })

        Row({ space: 12 }) {
          Button('上传到云端')
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

          Button('从云端拉取')
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

        Text('手动拉取会覆盖本机书签缓存；手动上传会覆盖云端该文件。GitHub 与 Gitee 之间数据格式相同，但不可混用同一 ID。')
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
