import type { FolderTreeNode } from '../model/IndexTypes';
import { sheetEnterExitTransition } from '../utils';

export interface NewBookmarkSheetProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  /** 只读区展示用：已去掉「收藏夹栏 / 」前缀，与主列表一致（如「杂项 / 」） */
  contentTertiary: Resource;
  optionRowPadH: number;
  newBookmarkFolderRowHeight: number;
  optionCardRadius: number;
  folderMaxDepth: number;
  rowClickEffect: ClickEffect;
  iconClickEffect: ClickEffect;
  newBookmarkTitle: string;
  newBookmarkUrl: string;
  newBookmarkIsCustomFolder: boolean;
  /** true：「新建文件夹（根级）」；false：在树中某文件夹下点「在此文件夹下新建」 */
  newBookmarkCustomIsRootLevel: boolean;
  newBookmarkSelectedFolderPath: string;
  /** 根级自定义：整段路径一个输入框 */
  newBookmarkFolderCustomPath: string;
  /** 在父下新建：只读父路径的展示文案（无「收藏夹栏 / 」） */
  newBookmarkCustomLockedDisplayPrefix: string;
  /** 在父下新建：可编辑后缀（新文件夹名，可含 / ） */
  newBookmarkCustomChildInput: string;
  folderTree: Array<FolderTreeNode>;
  isFolderExpanded: (fullPath: string) => boolean;
  folderDepthFromFullPath: (path: string) => number;
  onBack: () => void;
  onTitleChange: (value: string) => void;
  onUrlChange: (value: string) => void;
  onSelectFolder: (fullPath: string) => void;
  onToggleFolderExpand: (fullPath: string) => void;
  onEnableRootCustomFolder: () => void;
  onCreateChildFolder: (fullPath: string) => void;
  onCustomPathChange: (value: string) => void;
  onCustomChildInputChange: (value: string) => void;
  onConfirmAdd: () => void;
}

@Builder
function BuildNewBookmarkFolderTree(props: NewBookmarkSheetProps, nodes: Array<FolderTreeNode>, depth: number) {
  Column({ space: 8 }) {
    ForEach(nodes, (node: FolderTreeNode) => {
      Column({ space: 0 }) {
        Row() {
          Row() {
            Text(node.segmentLabel)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .margin({ left: depth * 14 })
            if (!props.newBookmarkIsCustomFolder &&
              props.newBookmarkSelectedFolderPath === node.fullPath) {
              SymbolGlyph($r('sys.symbol.checkmark'))
                .fontSize(18)
                .fontColor([$r('sys.color.ohos_id_color_emphasize')])
            }
          }
          .layoutWeight(1)
          .padding({
            left: props.optionRowPadH,
            right: 8,
            top: 10,
            bottom: 10
          })
          .onClick(() => {
            props.onSelectFolder(node.fullPath);
          })

          if (props.folderDepthFromFullPath(node.fullPath) < props.folderMaxDepth) {
            Row() {
              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(18)
                .fontColor([$r('sys.color.icon_tertiary')])
                .rotate({ angle: props.isFolderExpanded(node.fullPath) ? 90 : 0 })
                .animation({ duration: 200, curve: Curve.FastOutSlowIn })
            }
            .width(44)
            .height(44)
            .justifyContent(FlexAlign.Center)
            .clickEffect(props.iconClickEffect)
            .onClick(() => {
              props.onToggleFolderExpand(node.fullPath);
            })
          }
        }
        .width('100%')
        .constraintSize({ minHeight: props.newBookmarkFolderRowHeight })
        .borderRadius(12)
        .backgroundColor($r('app.color.card_background'))
        .border({
          width: (!props.newBookmarkIsCustomFolder &&
            props.newBookmarkSelectedFolderPath === node.fullPath) ? 2 : 1,
          color: (!props.newBookmarkIsCustomFolder &&
            props.newBookmarkSelectedFolderPath === node.fullPath) ?
            $r('sys.color.ohos_id_color_emphasize') :
            $r('app.color.card_border')
        })
        .alignItems(VerticalAlign.Center)

        if (props.isFolderExpanded(node.fullPath)) {
          Column({ space: 8 }) {
            if (node.children.length > 0) {
              BuildNewBookmarkFolderTree(props, node.children, depth + 1)
            }
            Button('＋ 在此文件夹下新建')
              .type(ButtonType.Normal)
              .width('100%')
              .height(props.newBookmarkFolderRowHeight)
              .fontSize(14)
              .fontColor(props.contentPrimary)
              .backgroundColor($r('app.color.card_background'))
              .border({ width: 1, color: $r('app.color.card_border') })
              .borderRadius(10)
              .onClick(() => {
                props.onCreateChildFolder(node.fullPath);
              })
          }
          .width('100%')
          .margin({ top: 4 })
        }
      }
      .width('100%')
    }, (node: FolderTreeNode) => node.fullPath)
  }
  .width('100%')
}

@Builder
export function BuildNewBookmarkSheet(props: NewBookmarkSheetProps) {
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
        Text('新建收藏')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
        Text('名称、网址与所在文件夹')
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
        Column({ space: 6 }) {
          Text('名称')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
          TextInput({ placeholder: '显示名称', text: props.newBookmarkTitle })
            .height(props.newBookmarkFolderRowHeight)
            .fontSize(16)
            .fontColor(props.contentPrimary)
            .placeholderColor(props.contentSecondary)
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('app.color.card_border') })
            .borderRadius(12)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => {
              props.onTitleChange(value);
            })
        }
        .width('100%')

        Column({ space: 6 }) {
          Text('网址')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
          TextInput({ placeholder: 'https:// 或域名（自动补全 https）', text: props.newBookmarkUrl })
            .height(props.newBookmarkFolderRowHeight)
            .fontSize(16)
            .fontColor(props.contentPrimary)
            .placeholderColor(props.contentSecondary)
            .backgroundColor($r('app.color.card_background'))
            .border({ width: 1, color: $r('app.color.card_border') })
            .borderRadius(12)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => {
              props.onUrlChange(value);
            })
        }
        .width('100%')

        Column({ space: 6 }) {
          Text('文件夹')
            .fontSize(13)
            .fontColor(props.contentSecondary)
            .width('100%')
          Text('左侧点选文件夹；右端「›」展开嵌套。展开后底部可在此文件夹下新建子路径（父 / 子 / …，最多 9 层）')
            .fontSize(12)
            .fontColor(props.contentSecondary)
            .width('100%')

          Scroll() {
            Column({ space: 8 }) {
              BuildNewBookmarkFolderTree(props, props.folderTree, 0)

              Row() {
                Text('＋ 新建文件夹（根级）…')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(props.contentPrimary)
                  .layoutWeight(1)
                if (props.newBookmarkIsCustomFolder && props.newBookmarkCustomIsRootLevel) {
                  SymbolGlyph($r('sys.symbol.checkmark'))
                    .fontSize(18)
                    .fontColor([$r('sys.color.ohos_id_color_emphasize')])
                }
              }
              .width('100%')
              .constraintSize({ minHeight: props.newBookmarkFolderRowHeight })
              .padding({
                left: props.optionRowPadH,
                right: props.optionRowPadH,
                top: 10,
                bottom: 10
              })
              .borderRadius(12)
              .backgroundColor($r('app.color.card_background'))
              .border({
                width: (props.newBookmarkIsCustomFolder && props.newBookmarkCustomIsRootLevel) ? 2 : 1,
                color: (props.newBookmarkIsCustomFolder && props.newBookmarkCustomIsRootLevel) ?
                  $r('sys.color.ohos_id_color_emphasize') :
                  $r('app.color.card_border')
              })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                props.onEnableRootCustomFolder();
              })
            }
            .width('100%')
          }
          .width('100%')
          .constraintSize({ maxHeight: 320 })
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)

          if (props.newBookmarkIsCustomFolder) {
            if (props.newBookmarkCustomIsRootLevel) {
              TextInput({
                placeholder: '例如：工作 / 项目A / 子项（留空则归入「未分类」）',
                text: props.newBookmarkFolderCustomPath
              })
                .height(props.newBookmarkFolderRowHeight)
                .fontSize(16)
                .fontColor(props.contentPrimary)
                .placeholderColor(props.contentSecondary)
                .backgroundColor($r('app.color.card_background'))
                .border({ width: 1, color: $r('app.color.card_border') })
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  props.onCustomPathChange(value);
                })
            } else {
              // 与主界面一致：不显示「收藏夹栏 / 」；父路径只读灰色，仅可编辑新文件夹段
              Row() {
                if (props.newBookmarkCustomLockedDisplayPrefix.length > 0) {
                  Text(props.newBookmarkCustomLockedDisplayPrefix)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(props.contentTertiary)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ right: 6 })
                    .flexShrink(0)
                }
                TextInput({
                  placeholder: '新文件夹名称（可含子层，用 / 分隔）',
                  text: props.newBookmarkCustomChildInput
                })
                  .layoutWeight(1)
                  .height(props.newBookmarkFolderRowHeight)
                  .fontSize(16)
                  .fontColor(props.contentPrimary)
                  .placeholderColor(props.contentSecondary)
                  .backgroundColor(Color.Transparent)
                  .padding({ left: 0, right: 0 })
                  .onChange((value: string) => {
                    props.onCustomChildInputChange(value);
                  })
              }
              .width('100%')
              .constraintSize({ minHeight: props.newBookmarkFolderRowHeight })
              .padding({ left: 12, right: 12 })
              .alignItems(VerticalAlign.Center)
              .backgroundColor($r('app.color.card_background'))
              .border({
                width: 2,
                color: $r('sys.color.ohos_id_color_emphasize')
              })
              .borderRadius(12)
            }
          }
        }
        .width('100%')

        Button('确认添加')
          .type(ButtonType.Normal)
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
          .borderRadius(12)
          .margin({ top: 8 })
          .onClick(() => {
            props.onConfirmAdd();
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
  .transition(sheetEnterExitTransition())
  .backgroundColor(props.navChromeBg)
}
