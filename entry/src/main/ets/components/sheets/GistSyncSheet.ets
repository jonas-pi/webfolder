import { sheetEnterExitTransition } from '../../utils';
import { GIST_PROVIDER_GITHUB, GIST_PROVIDER_GITEE, GIST_PROVIDER_WEBDAV } from '../../model/GistSyncSettings';

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
  webDavUrl: string;
  webDavUsername: string;
  webDavPassword: string;
  syncBusy: boolean;
  githubQuickConnectBusy: boolean;
  giteeQuickConnectBusy: boolean;
  githubQuickConnectReady: boolean;
  githubQuickConnectUserCode: string;
  githubQuickConnectVerificationUri: string;
  githubQuickConnectStatusText: string;
  githubManualConfigExpanded: boolean;
  giteeManualConfigExpanded: boolean;
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
  onWebDavUrlChange: (v: string) => void;
  onWebDavUsernameChange: (v: string) => void;
  onWebDavPasswordChange: (v: string) => void;
  onGithubQuickConnect: () => void;
  onGithubCopyUserCode: () => void;
  onGiteeOpenTokenPage: () => void;
  onGiteeQuickConnect: () => void;
  onGithubManualConfigToggle: () => void;
  onGiteeManualConfigToggle: () => void;
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
        Text('GitHub Gist、Gitee 代码片段或 WebDAV · 载荷与 BookmarkHub 一致')
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
        Row({ space: 8 }) {
          Button('GitHub Gist')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
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
            .fontSize(14)
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
          Button('WebDAV')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .fontColor(props.gistProvider === GIST_PROVIDER_WEBDAV ? Color.White : props.contentPrimary)
            .backgroundColor(props.gistProvider === GIST_PROVIDER_WEBDAV ?
              $r('sys.color.ohos_id_color_emphasize') : $r('app.color.card_background'))
            .border({
              width: 1,
              color: props.gistProvider === GIST_PROVIDER_WEBDAV ?
                $r('sys.color.ohos_id_color_emphasize') : $r('app.color.card_border')
            })
            .borderRadius(12)
            .enabled(!props.syncBusy)
            .onClick(() => {
              props.onProviderChange(GIST_PROVIDER_WEBDAV);
            })
        }
        .width('100%')
        Text('GitHub、Gitee 与 WebDAV 配置分别保存；切换同步源仅切换当前上传/拉取使用的云端。')
          .fontSize(12)
          .fontColor(props.contentSecondary)
          .width('100%')
          .lineHeight(18)

        if (props.gistProvider === GIST_PROVIDER_WEBDAV) {
          Text('填写指向 BookmarkHub JSON 文件的 WebDAV 完整地址；上传会 PUT 覆盖该文件，拉取会 GET 读取该文件。')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
        } else if (props.gistProvider === GIST_PROVIDER_GITEE) {
          Text('填写 Gitee 私人令牌后可自动创建或复用私密代码片段；文件名建议与其它端一致（默认 BookmarkHub）。')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
        } else {
          Text('可连接 GitHub 自动创建或复用 Secret Gist；也可继续手动填写 Token、Gist ID 与文件名。')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
        }

        if (props.gistProvider === GIST_PROVIDER_GITHUB) {
          Column({ space: 8 }) {
            Button(props.githubQuickConnectBusy ?
              (props.githubQuickConnectStatusText.length > 0 ? props.githubQuickConnectStatusText : '等待 GitHub 授权…') :
              '连接 GitHub 自动配置')
              .type(ButtonType.Normal)
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
              .borderRadius(12)
              .enabled(!props.syncBusy)
              .clickEffect(props.rowClickEffect)
              .onClick(() => {
                props.onGithubQuickConnect();
              })

            if (!props.githubQuickConnectReady) {
              Text('开发版未配置 OAuth Client ID，暂时使用下方手动配置。')
                .fontSize(12)
                .fontColor(props.contentSecondary)
                .width('100%')
                .lineHeight(18)
            }

            if (props.githubQuickConnectUserCode.length > 0) {
              Column({ space: 8 }) {
                Row() {
                  Text('验证码')
                    .fontSize(13)
                    .fontColor(props.contentSecondary)
                  Text(props.githubQuickConnectUserCode)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(props.contentPrimary)
                    .layoutWeight(1)
                    .textAlign(TextAlign.End)
                }
                .width('100%')

                Button('点击复制')
                  .type(ButtonType.Normal)
                  .width('100%')
                  .height(40)
                  .fontSize(14)
                  .fontColor($r('sys.color.ohos_id_color_emphasize'))
                  .backgroundColor(Color.Transparent)
                  .border({ width: 1, color: $r('sys.color.ohos_id_color_emphasize') })
                  .borderRadius(10)
                  .clickEffect(props.rowClickEffect)
                  .onClick(() => {
                    props.onGithubCopyUserCode();
                  })
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .borderRadius(12)
              .backgroundColor($r('app.color.card_background'))
              .border({ width: 1, color: $r('app.color.card_border') })

              Text('授权页：' + props.githubQuickConnectVerificationUri)
                .fontSize(12)
                .fontColor(props.contentSecondary)
                .width('100%')
                .lineHeight(18)
            }
          }
          .width('100%')
        }

        if (props.gistProvider === GIST_PROVIDER_GITEE) {
          Column({ space: 8 }) {
            Button('打开 Gitee 令牌页')
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
                props.onGiteeOpenTokenPage();
              })

            Text('Gitee 私人令牌')
              .fontSize(13)
              .fontColor(props.contentSecondary)
              .width('100%')
            TextInput({
              text: props.giteeToken,
              placeholder: 'Gitee 私人令牌'
            })
              .height(48)
              .fontSize(15)
              .fontColor(props.contentPrimary)
              .type(InputType.Normal)
              .backgroundColor($r('app.color.card_background'))
              .border({ width: 1, color: $r('app.color.card_border') })
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .enabled(!props.syncBusy)
              .onChange((v: string) => {
                props.onGiteeTokenChange(v);
              })

            Button(props.giteeQuickConnectBusy ? '正在配置 Gitee…' : '用当前令牌自动配置')
              .type(ButtonType.Normal)
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
              .borderRadius(12)
              .enabled(!props.syncBusy)
              .clickEffect(props.rowClickEffect)
              .onClick(() => {
                props.onGiteeQuickConnect();
              })
          }
          .width('100%')
        }

        if (props.gistProvider === GIST_PROVIDER_WEBDAV) {
          Text('WebDAV 文件地址')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
          TextInput({
            text: props.webDavUrl,
            placeholder: 'https://dav.example.com/BookmarkHub/bookmarks.json'
          })
            .height(48)
            .fontSize(15)
            .fontColor(props.contentPrimary)
            .type(InputType.Normal)
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('app.color.card_border') })
            .borderRadius(12)
            .padding({ left: 12, right: 12 })
            .enabled(!props.syncBusy)
            .onChange((v: string) => {
              props.onWebDavUrlChange(v);
            })

          Text('用户名')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
          TextInput({
            text: props.webDavUsername,
            placeholder: 'WebDAV 用户名'
          })
            .height(48)
            .fontSize(15)
            .fontColor(props.contentPrimary)
            .type(InputType.Normal)
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('app.color.card_border') })
            .borderRadius(12)
            .padding({ left: 12, right: 12 })
            .enabled(!props.syncBusy)
            .onChange((v: string) => {
              props.onWebDavUsernameChange(v);
            })

          Text('密码或应用密码')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
          TextInput({
            text: props.webDavPassword,
            placeholder: '仅保存本机'
          })
            .height(48)
            .fontSize(15)
            .fontColor(props.contentPrimary)
            .type(InputType.Normal)
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('app.color.card_border') })
            .borderRadius(12)
            .padding({ left: 12, right: 12 })
            .enabled(!props.syncBusy)
            .onChange((v: string) => {
              props.onWebDavPasswordChange(v);
            })
        } else {
          if (props.gistProvider === GIST_PROVIDER_GITHUB) {
            Row() {
              Text('手动配置')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(props.contentPrimary)
                .layoutWeight(1)
              SymbolGlyph(props.githubManualConfigExpanded ?
                $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
                .fontSize(18)
                .fontColor([$r('sys.color.icon_secondary')])
            }
            .width('100%')
            .height(48)
            .padding({ left: 12, right: 12 })
            .borderRadius(12)
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('app.color.card_border') })
            .enabled(!props.syncBusy)
            .onClick(() => {
              props.onGithubManualConfigToggle();
            })
          }

          if (props.gistProvider === GIST_PROVIDER_GITEE) {
            Row() {
              Text('高级手动配置')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(props.contentPrimary)
                .layoutWeight(1)
              SymbolGlyph(props.giteeManualConfigExpanded ?
                $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
                .fontSize(18)
                .fontColor([$r('sys.color.icon_secondary')])
            }
            .width('100%')
            .height(48)
            .padding({ left: 12, right: 12 })
            .borderRadius(12)
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('app.color.card_border') })
            .enabled(!props.syncBusy)
            .onClick(() => {
              props.onGiteeManualConfigToggle();
            })
          }

          if (props.gistProvider === GIST_PROVIDER_GITHUB && props.githubManualConfigExpanded) {
            Text('访问令牌')
              .fontSize(13)
              .fontColor(props.contentSecondary)
              .width('100%')
            TextInput({
              text: props.githubToken,
              placeholder: 'ghp_xxxxxxxx'
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
                props.onGithubTokenChange(v);
              })

            Text('片段 ID')
              .fontSize(13)
              .fontColor(props.contentSecondary)
              .width('100%')
            TextInput({
              text: props.githubGistId,
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
                props.onGithubGistIdChange(v);
              })

            Text('片段内文件名')
              .fontSize(13)
              .fontColor(props.contentSecondary)
              .width('100%')
            TextInput({
              text: props.githubFileName,
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
                props.onGithubFileNameChange(v);
              })
          }

          if (props.gistProvider === GIST_PROVIDER_GITEE && props.giteeManualConfigExpanded) {
            Text('片段 ID')
              .fontSize(13)
              .fontColor(props.contentSecondary)
              .width('100%')
            TextInput({
              text: props.giteeGistId,
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
                props.onGiteeGistIdChange(v);
              })

            Text('片段内文件名')
              .fontSize(13)
              .fontColor(props.contentSecondary)
              .width('100%')
            TextInput({
              text: props.giteeFileName,
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
                props.onGiteeFileNameChange(v);
              })
          }
        }

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

        Text('手动拉取会覆盖本机书签缓存；手动上传会覆盖当前云端文件。GitHub、Gitee 与 WebDAV 数据格式相同，但凭据与定位信息不可混用。')
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
