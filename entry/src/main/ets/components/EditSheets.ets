import type { FolderTreeNode } from '../model/IndexTypes';
import { sheetEnterExitTransition } from '../utils';

export interface FolderRenameSheetProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  folderRenameInput: string;
  onBack: () => void;
  onInputChange: (v: string) => void;
  onConfirm: () => void;
}

export interface BookmarkEditSheetProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  rowHeight: number;
  bookmarkEditTitle: string;
  bookmarkEditUrl: string;
  onBack: () => void;
  onTitleChange: (v: string) => void;
  onUrlChange: (v: string) => void;
  onSave: () => void;
}

export interface MoveBookmarkSheetProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  optionRowPadH: number;
  rowHeight: number;
  iconClickEffect: ClickEffect;
  moveBookmarkTitle: string;
  moveBookmarkTargetFolder: string;
  folderTree: Array<FolderTreeNode>;
  isFolderExpanded: (fullPath: string) => boolean;
  onBack: () => void;
  onSelectTarget: (path: string) => void;
  onToggleFolderExpand: (fullPath: string) => void;
  onConfirmMove: () => void;
}

@Builder
export function BuildFolderRenameSheet(props: FolderRenameSheetProps) {
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
        Text('重命名文件夹')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
        Text('支持「父 / 子 / …」嵌套路径，最多 9 层')
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
      Column({ space: 12 }) {
        TextInput({ text: props.folderRenameInput, placeholder: '新的文件夹路径' })
          .height(48)
          .fontSize(16)
          .fontColor(props.contentPrimary)
          .backgroundColor($r('app.color.card_background'))
          .border({ width: 1, color: $r('app.color.card_border') })
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .onChange((v: string) => {
            props.onInputChange(v);
          })

        Button('确认重命名')
          .type(ButtonType.Normal)
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontColor(Color.White)
          .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
          .borderRadius(12)
          .onClick(() => {
            props.onConfirm();
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

@Builder
export function BuildBookmarkEditSheet(props: BookmarkEditSheetProps) {
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
        Text('编辑书签')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
        Text('修改名称与网址')
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
          TextInput({ placeholder: '显示名称', text: props.bookmarkEditTitle })
            .height(props.rowHeight)
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
          TextInput({ placeholder: 'https:// 或域名（自动补全 https）', text: props.bookmarkEditUrl })
            .height(props.rowHeight)
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

        Button('保存')
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
            props.onSave();
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

/** 移动书签：树形文件夹选择器（递归，互斥展开由调用方控制） */
@Builder
function BuildMoveFolderTree(props: MoveBookmarkSheetProps, nodes: Array<FolderTreeNode>, depth: number) {
  Column({ space: 8 }) {
    ForEach(nodes, (node: FolderTreeNode) => {
      Column({ space: 0 }) {
        Row() {
          // 左侧：文件夹名 + 选中勾
          Row() {
            Text(node.segmentLabel)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(props.contentPrimary)
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: depth * 14 })
            if (props.moveBookmarkTargetFolder === node.fullPath) {
              SymbolGlyph($r('sys.symbol.checkmark'))
                .fontSize(18)
                .fontColor([$r('sys.color.ohos_id_color_emphasize')])
            }
          }
          .layoutWeight(1)
          .padding({ left: props.optionRowPadH, right: 8, top: 10, bottom: 10 })
          .onClick(() => { props.onSelectTarget(node.fullPath); })

          // 右侧：有子文件夹时显示展开/折叠箭头
          if (node.children.length > 0) {
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
            .onClick(() => { props.onToggleFolderExpand(node.fullPath); })
          }
        }
        .width('100%')
        .constraintSize({ minHeight: props.rowHeight })
        .borderRadius(12)
        .backgroundColor($r('app.color.card_background'))
        .border({
          width: props.moveBookmarkTargetFolder === node.fullPath ? 2 : 1,
          color: props.moveBookmarkTargetFolder === node.fullPath
            ? $r('sys.color.ohos_id_color_emphasize')
            : $r('app.color.card_border')
        })
        .alignItems(VerticalAlign.Center)

        // 展开后递归渲染子节点
        if (props.isFolderExpanded(node.fullPath)) {
          Column({ space: 8 }) {
            BuildMoveFolderTree(props, node.children, depth + 1)
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
export function BuildMoveBookmarkSheet(props: MoveBookmarkSheetProps) {
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
      .onClick(() => { props.onBack(); })

      Column() {
        Text('移动到文件夹')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
        Text('点选目标文件夹后确认；右端「›」展开子文件夹')
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
        Text(`「${props.moveBookmarkTitle}」`)
          .fontSize(14)
          .fontColor(props.contentSecondary)
          .width('100%')
          .maxLines(2)

        Text('目标文件夹')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')

        Scroll() {
          Column({ space: 8 }) {
            BuildMoveFolderTree(props, props.folderTree, 0)
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({ maxHeight: 400 })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)

        Button('确认移动')
          .type(ButtonType.Normal)
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontColor(Color.White)
          .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
          .borderRadius(12)
          .margin({ top: 8 })
          .onClick(() => { props.onConfirmMove(); })
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
