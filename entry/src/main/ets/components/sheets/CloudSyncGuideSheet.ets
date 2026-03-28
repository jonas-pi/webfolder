import { sheetEnterExitTransition } from '../../utils';

/** 说明页外链（与内嵌文案对应，便于跳转浏览器） */
const URL_BOOKMARKHUB_REPO_GITHUB: string = 'https://github.com/jonas-pi/BookmarkHub';
const URL_BOOKMARKHUB_REPO_GITEE: string = 'https://gitee.com/Jonas-yews/BookmarkHub';
const URL_GITHUB_NEW_GIST: string = 'https://gist.github.com/';
const URL_GITHUB_PAT_CLASSIC: string = 'https://github.com/settings/tokens';
const URL_GITHUB_PAT_FINE: string = 'https://github.com/settings/personal-access-tokens';
const URL_GITEE_PERSONAL_TOKEN: string = 'https://gitee.com/personal_access_tokens';
const URL_GITEE_MY_SNIPPETS: string = 'https://gitee.com/mine/snippets';

export interface CloudSyncGuideSheetProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  onBack: () => void;
  /** 在系统浏览器中打开 https 链接 */
  onOpenExternalUrl: (url: string) => void;
}

@Builder
export function BuildCloudSyncGuideSheet(props: CloudSyncGuideSheetProps) {
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
        Text('云端同步使用说明')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
        Text('与仓库 docs/云端同步使用说明.md 一致')
          .fontSize(12)
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
      Column({ space: 0 }) {
        Text('本应用通过 GitHub Gist 或 Gitee 代码片段存储与 BookmarkHub 相同格式的书签数据（SyncDataInfo）。以下为创建云端片段与本应用字段说明。')
          .fontSize(14)
          .fontColor(props.contentSecondary)
          .width('100%')
          .lineHeight(22)
        Text('拓展仓库（点击下列链接在浏览器打开）')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(props.contentPrimary)
          .width('100%')
          .margin({ top: 8 })
        Text(URL_BOOKMARKHUB_REPO_GITHUB + '（GitHub）')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .decoration({ type: TextDecorationType.Underline })
          .width('100%')
          .margin({ top: 6 })
          .onClick((): void => {
            props.onOpenExternalUrl(URL_BOOKMARKHUB_REPO_GITHUB);
          })
        Text(URL_BOOKMARKHUB_REPO_GITEE + '（Gitee）')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .decoration({ type: TextDecorationType.Underline })
          .width('100%')
          .margin({ top: 6 })
          .onClick((): void => {
            props.onOpenExternalUrl(URL_BOOKMARKHUB_REPO_GITEE);
          })

        Text('一、本应用里要填什么（字段对照）')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
          .width('100%')
          .margin({ top: 16, bottom: 8 })
        Text('路径：我的 → 云端同步。')
          .fontSize(14)
          .fontColor(props.contentSecondary)
          .width('100%')
          .lineHeight(22)
        Text('• 同步源：选 GitHub Gist 或 Gitee 片段。与浏览器扩展「云端类型」对应；两种云端片段 ID、令牌不可混用。')
          .fontSize(14)
          .fontColor(props.contentSecondary)
          .width('100%')
          .lineHeight(22)
          .margin({ top: 6 })
        Text('• 访问令牌：GitHub 为 Personal Access Token；Gitee 为私人令牌。仅保存在本机，请勿泄露。')
          .fontSize(14)
          .fontColor(props.contentSecondary)
          .width('100%')
          .lineHeight(22)
          .margin({ top: 6 })
        Text('• 片段 ID：云端分配的唯一标识。只填 ID 字符串，不要填整段浏览器 URL。')
          .fontSize(14)
          .fontColor(props.contentSecondary)
          .width('100%')
          .lineHeight(22)
          .margin({ top: 6 })
        Text('• 片段内文件名：该片段里那一个 JSON 文件的文件名。多设备须完全一致；默认建议 BookmarkHub（与创建片段时文件名一致即可）。')
          .fontSize(14)
          .fontColor(props.contentSecondary)
          .width('100%')
          .lineHeight(22)
          .margin({ top: 6 })
        Text('若使用浏览器扩展，请对齐：gistProvider（github / gitee）、githubToken、gistID、gistFileName。')
          .fontSize(14)
          .fontColor(props.contentSecondary)
          .width('100%')
          .lineHeight(22)
          .margin({ top: 8 })

        Text('二、GitHub：创建 Gist 与令牌')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
          .width('100%')
          .margin({ top: 16, bottom: 8 })
        Text('快捷链接')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(props.contentPrimary)
          .width('100%')
        Text(URL_GITHUB_NEW_GIST + '（新建 Gist）')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .decoration({ type: TextDecorationType.Underline })
          .width('100%')
          .margin({ top: 6 })
          .onClick((): void => {
            props.onOpenExternalUrl(URL_GITHUB_NEW_GIST);
          })
        Text(URL_GITHUB_PAT_CLASSIC + '（Classic 个人访问令牌）')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .decoration({ type: TextDecorationType.Underline })
          .width('100%')
          .margin({ top: 6 })
          .onClick((): void => {
            props.onOpenExternalUrl(URL_GITHUB_PAT_CLASSIC);
          })
        Text(URL_GITHUB_PAT_FINE + '（Fine-grained 令牌，需为 Gist 勾选权限）')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .decoration({ type: TextDecorationType.Underline })
          .width('100%')
          .margin({ top: 6, bottom: 8 })
          .onClick((): void => {
            props.onOpenExternalUrl(URL_GITHUB_PAT_FINE);
          })
        Text('1）Settings → Developer settings → Personal access tokens。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22)
        Text('2）Tokens (classic)：Generate new token (classic)，勾选 gist 权限；生成后复制令牌（常以 ghp_ 开头）。若用 Fine-grained token，请为 Gists 勾选读写（以 GitHub 页面为准）。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
        Text('3）将令牌粘贴到本应用「访问令牌」。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
        Text('4）打开 gist.github.com，在 Filename including extension… 填写与「片段内文件名」一致的名称（如 BookmarkHub）。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
        Text('5）内容可先填 {}；选择 Create secret gist（私密）。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
        Text('6）地址栏 URL 形如 https://gist.github.com/<用户名>/<gist_id>，最后一段 gist_id 即「片段 ID」。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })

        Text('三、Gitee：代码片段与私人令牌')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
          .width('100%')
          .margin({ top: 16, bottom: 8 })
        Text('快捷链接')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(props.contentPrimary)
          .width('100%')
        Text(URL_GITEE_PERSONAL_TOKEN + '（私人令牌）')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .decoration({ type: TextDecorationType.Underline })
          .width('100%')
          .margin({ top: 6 })
          .onClick((): void => {
            props.onOpenExternalUrl(URL_GITEE_PERSONAL_TOKEN);
          })
        Text(URL_GITEE_MY_SNIPPETS + '（我的代码片段，可在此新建）')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .decoration({ type: TextDecorationType.Underline })
          .width('100%')
          .margin({ top: 6, bottom: 8 })
          .onClick((): void => {
            props.onOpenExternalUrl(URL_GITEE_MY_SNIPPETS);
          })
        Text('Gitee 称「代码片段」；Open API 路径仍为 /gists/…。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22)
        Text('1）设置 → 安全设置 → 私人令牌（或 gitee.com/personal_access_tokens）。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
        Text('2）生成令牌时勾选代码片段 / gists 相关权限（常见 scope 为 gists；以 Gitee 页面为准）。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
        Text('3）新建代码片段，可见性选私密；添加文件，文件名与「片段内文件名」一致（如 BookmarkHub），内容可先填 {}。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
        Text('4）保存后从片段页 URL 取片段 ID（仅标识符，非整段 https URL）。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })

        Text('四、使用注意')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
          .width('100%')
          .margin({ top: 16, bottom: 8 })
        Text('• 数据格式相同，但 GitHub 与 Gitee 的 Token、片段 ID 不可混用；切换同步源须整套重配。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22)
        Text('• 上传到云端会覆盖远端该文件；从云端拉取会覆盖本机书签缓存。首次使用前请备份。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
        Text('• 本应用通过 HTTPS 访问 api.github.com 或 gitee.com/api/v5。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })

        Text('五、接口与术语（供核对）')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
          .width('100%')
          .margin({ top: 16, bottom: 8 })
        Text('GitHub：Authorization: Bearer <token>，REST Gists API。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22)
        Text('Gitee：查询参数 access_token=<token>，OpenAPI v5 /gists/{id} 等。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
        Text('界面「片段」在 GitHub 侧即 Gist，在 Gitee 侧即代码片段。')
          .fontSize(14).fontColor(props.contentSecondary).width('100%').lineHeight(22).margin({ top: 6 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 32 })
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
  .width('100%')
  .height('100%')
  .transition(sheetEnterExitTransition())
}
