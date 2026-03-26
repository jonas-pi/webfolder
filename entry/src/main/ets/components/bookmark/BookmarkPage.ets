import type {
  BookmarkGroup, BookmarkItem, BookmarkNavForest, BookmarkNavNode, SwipeTxEntry
} from '../../model/IndexTypes';
import {
  TITLE_CONTENT_GAP_VP, BOOKMARK_LIST_SCROLL_EDGE_BOTTOM_VP,
  BOOKMARK_LIST_DRAG_EDGE_BLEED_VP, OPTION_ROW_PAD_H_VP
} from '../../constants/AppLayout';
import { buildBookmarkNavForest } from '../../utils';

/** 主列表根级槽位（与 ForEach + onMove 配合，ArkUI 的 List 不支持 onMove） */
interface BookmarkRootSlot {
  key: string;
  /** 0=收藏夹栏条，1=收藏夹栏下某根文件夹，2=未分类 */
  slotType: number;
  barRootNode: BookmarkNavNode | null;
}

/**
 * 收藏夹列表组件。
 *
 * ArkTS swipeAction.end.builder 规则：
 *  - builder 属性不能直接写内联 UI（Row/Button 等），否则编译报"UI component cannot be used here"
 *  - builder 属性不能用 this，否则报 arkts-no-standalone-this
 *  - 正确写法：builder: () => { this.MyBuilder(params) } ——在 @Builder 方法里写 UI
 */
@Component
export struct BookmarkPageComp {
  /**
   * 书签分组数据（父级 @State 经 @Prop 传入）。
   * 父组件在外层容器上为数据变更设置唯一 .id()，避免 List/ForEach 节点复用导致界面滞后。
   */
  @Prop bookmarkGroups: Array<BookmarkGroup> = [];
  /** 递增时强制重建 List，用于关闭所有侧滑面板 */
  @Prop bookmarkSwipeRestoreKey: number = 0;
  /** 侧滑按钮 translate.x 状态；父级 @State 变更时同步，驱动本组件重渲染 */
  @Prop swipeActionTranslateEntries: Array<SwipeTxEntry> = [];
  /** 已展开文件夹路径 */
  @Prop expandedFolders: Array<string> = [];
  /** 与父级 bookmarkRenderEpoch 同步，绑定到根节点 id，确保子树随版本重建 */
  @Prop bookmarkRenderEpoch: number = 0;

  swipeActionIconBtn: number = 44;
  optionRowMinHeight: number = 64;
  optionRowPadH: number = 16;
  optionRowPadV: number = 8;
  optionCardRadius: number = 24;
  rowClickEffect: ClickEffect = { level: ClickEffectLevel.MIDDLE, scale: 0.95 };
  contentPrimary: Resource = $r('sys.color.ohos_id_color_text_primary');
  contentSecondary: Resource = $r('sys.color.ohos_id_color_text_secondary');

  isFolderExpanded: (folder: string) => boolean = (_f: string): boolean => false;
  onToggleFolder: (folder: string) => void = (_f: string): void => {};
  isFaviconFailed: (url: string) => boolean = (_u: string): boolean => false;
  faviconSource: (url: string) => string = (_u: string): string => '';
  markFaviconFailed: (url: string) => void = (_u: string): void => {};
  titleInitial: (title: string) => string = (_t: string): string => '';
  itemTransition: (itemIndex: number) => TransitionEffect =
    (_i: number): TransitionEffect => TransitionEffect.OPACITY;

  onOpenBookmark: (url: string) => void = (_u: string): void => {};
  onReorderBookmarkItems: (folder: string, from: number, to: number) => void =
    (_f: string, _from: number, _to: number): void => {};
  onReorderBookmarkGroups: (from: number, to: number) => void =
    (_from: number, _to: number): void => {};
  /** 父文件夹路径下，直接子文件夹排序（与 bookmarkGroups 中同级块顺序一致） */
  onReorderChildFolders: (parentFolderPath: string, from: number, to: number) => void =
    (_p: string, _from: number, _to: number): void => {};

  folderSwipeTranslateX: (folder: string) => number = (_f: string): number => 0;
  bookmarkSwipeTranslateX: (folder: string, url: string) => number =
    (_f: string, _u: string): number => 0;
  onFolderSwipeVisibleRatio: (folder: string, ratio: number) => void =
    (_f: string, _r: number): void => {};
  onBookmarkSwipeVisibleRatio: (folder: string, url: string, ratio: number) => void =
    (_f: string, _u: string, _r: number): void => {};

  onStartRenameFolder: (folder: string) => void = (_f: string): void => {};
  onDeleteFolder: (folder: string) => void = (_f: string): void => {};
  onMoveBookmark: (folder: string, item: BookmarkItem) => void =
    (_f: string, _item: BookmarkItem): void => {};
  onEditBookmark: (folder: string, item: BookmarkItem) => void =
    (_f: string, _item: BookmarkItem): void => {};
  onDeleteBookmark: (folder: string, item: BookmarkItem) => void =
    (_f: string, _item: BookmarkItem): void => {};

  private buildRootSlotList(forest: BookmarkNavForest): Array<BookmarkRootSlot> {
    const out: Array<BookmarkRootSlot> = [];
    if (forest.favBarGroup !== null) {
      out.push({
        key: `slot_fav_${this.bookmarkSwipeRestoreKey}`,
        slotType: 0,
        barRootNode: null
      });
    }
    let ri: number = 0;
    while (ri < forest.barFolderRoots.length) {
      const n: BookmarkNavNode = forest.barFolderRoots[ri];
      out.push({
        key: `slot_root_${this.bookmarkSwipeRestoreKey}_${n.folder}`,
        slotType: 1,
        barRootNode: n
      });
      ri++;
    }
    if (forest.unclassifiedGroup !== null) {
      out.push({
        key: `slot_uncl_${this.bookmarkSwipeRestoreKey}`,
        slotType: 2,
        barRootNode: null
      });
    }
    return out;
  }

  // ── 文件夹行左滑面板 ──────────────────────────────────────────────────────
  @Builder
  private FolderSwipeEndBuilder(folder: string) {
    Row({ space: 10 }) {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.square_and_pencil'))
          .fontSize(22)
          .fontColor([Color.White])
      }
      .width(this.swipeActionIconBtn)
      .height(this.swipeActionIconBtn)
      .backgroundColor('#007AFF')
      .onClick(() => {
        this.onStartRenameFolder(folder);
      })

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.trash_fill'))
          .fontSize(22)
          .fontColor([Color.White])
      }
      .width(this.swipeActionIconBtn)
      .height(this.swipeActionIconBtn)
      .backgroundColor('#E84026')
      .onClick(() => {
        this.onDeleteFolder(folder);
      })
    }
    .height(this.optionRowMinHeight)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 10, right: 12 })
    .translate({ x: this.folderSwipeTranslateX(folder) })
    .onVisibleAreaChange(
      [0.0, 0.08, 0.16, 0.24, 0.32, 0.5, 0.68, 0.84, 1.0],
      (_isVisible: boolean, currentRatio: number) => {
        this.onFolderSwipeVisibleRatio(folder, currentRatio);
      })
  }

  // ── 书签行左滑面板 ────────────────────────────────────────────────────────
  @Builder
  private BookmarkSwipeEndBuilder(folder: string, item: BookmarkItem) {
    Row({ space: 10 }) {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.folder'))
          .fontSize(22)
          .fontColor([Color.White])
      }
      .width(this.swipeActionIconBtn)
      .height(this.swipeActionIconBtn)
      .backgroundColor('#5AC8FA')
      .onClick(() => {
        this.onMoveBookmark(folder, item);
      })

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.square_and_pencil'))
          .fontSize(22)
          .fontColor([Color.White])
      }
      .width(this.swipeActionIconBtn)
      .height(this.swipeActionIconBtn)
      .backgroundColor('#007AFF')
      .onClick(() => {
        this.onEditBookmark(folder, item);
      })

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.trash_fill'))
          .fontSize(22)
          .fontColor([Color.White])
      }
      .width(this.swipeActionIconBtn)
      .height(this.swipeActionIconBtn)
      .backgroundColor('#E84026')
      .onClick(() => {
        this.onDeleteBookmark(folder, item);
      })
    }
    .height(this.optionRowMinHeight)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 10, right: 12 })
    .translate({ x: this.bookmarkSwipeTranslateX(folder, item.url) })
    .onVisibleAreaChange(
      [0.0, 0.08, 0.16, 0.24, 0.32, 0.5, 0.68, 0.84, 1.0],
      (_isVisible: boolean, currentRatio: number) => {
        this.onBookmarkSwipeVisibleRatio(folder, item.url, currentRatio);
      })
  }

  /**
   * 展开判断：直接读 @Prop expandedFolders，使响应式更新生效。
   * 不使用 isFolderExpanded 回调，避免闭包在 ForEach 内不触发重渲染的问题。
   */
  private isExpanded(folder: string): boolean {
    return this.expandedFolders.indexOf(folder) >= 0;
  }

  /** 显示名：去掉"收藏夹栏 / "前缀 */
  private displayName(folder: string): string {
    const prefix: string = '收藏夹栏 / ';
    return folder.startsWith(prefix) ? folder.slice(prefix.length) : folder;
  }

  /**
   * 根据标题首字符决定占位背景色（哈希选色，保证同一网站颜色稳定）。
   * 颜色取自 Material Design 系列，在浅色/深色模式下均有足够对比度。
   */
  private fallbackBgColor(title: string): string {
    const palette: Array<string> = [
      '#4A90D9', '#27AE60', '#E67E22', '#9B59B6',
      '#C0392B', '#16A085', '#2471A3', '#D4AC0D'
    ];
    if (title.length === 0) { return palette[0]; }
    return palette[title.charCodeAt(0) % palette.length];
  }

  // ── 书签条目列表（被文件夹卡片复用） ────────────────────────────────────────
  @Builder
  private BookmarkItemsListBuilder(group: BookmarkGroup) {
    List() {
      ForEach(group.items, (item: BookmarkItem, itemIndex: number) => {
        ListItem() {
          Column() {
            if (itemIndex > 0) {
              Divider()
                .strokeWidth(0.5)
                .color($r('app.color.card_border'))
                .margin({ left: 56, right: 12 })
            }
            Row() {
              if (!this.isFaviconFailed(item.url) && this.faviconSource(item.url).length > 0) {
                Image(this.faviconSource(item.url))
                  .width(28)
                  .height(28)
                  .borderRadius(6)
                  .objectFit(ImageFit.Contain)
                  .onError(() => { this.markFaviconFailed(item.url); })
              } else {
                Text(this.titleInitial(item.title))
                  .fontSize(13)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
                  .width(28)
                  .height(28)
                  .textAlign(TextAlign.Center)
                  .borderRadius(6)
                  .backgroundColor(this.fallbackBgColor(item.title))
              }
              Column() {
                Text(item.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Regular)
                  .fontColor(this.contentPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.url)
                  .fontSize(12)
                  .fontColor(this.contentSecondary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 12 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .transition(this.itemTransition(itemIndex))
          .clickEffect(this.rowClickEffect)
          .onClick(() => { this.onOpenBookmark(item.url); })
        }
        .draggable(true)
        .swipeAction({
          end: {
            builder: () => { this.BookmarkSwipeEndBuilder(group.folder, item); }
          }
        })
      }, (item: BookmarkItem, idx: number) =>
        `${this.bookmarkSwipeRestoreKey}_${group.folder}_${idx}_${item.url}_${item.title}`)
        .onMove((from: number, to: number) => {
          this.onReorderBookmarkItems(group.folder, from, to);
        })
    }
    .width('100%')
    .padding({ top: 4, bottom: 8 })
  }

  /**
   * 「收藏夹栏 /」下多级路径：按树嵌套展示，标题仅显示当前层 segment（与主列表逻辑一致）。
   */
  @Builder
  private BookmarkNavFolderBlock(node: BookmarkNavNode, depth: number) {
    Column() {
      Row() {
        Column() {
          Text(node.segmentLabel)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.contentPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`${node.items.length} 项`)
            .fontSize(14)
            .fontColor(this.contentSecondary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([$r('sys.color.icon_tertiary')])
          .rotate({ angle: this.isExpanded(node.folder) ? 90 : 0 })
          .animation({ duration: 400, curve: Curve.Friction })
      }
      .width('100%')
      .height(this.optionRowMinHeight)
      .padding({
        left: this.optionRowPadH,
        right: this.optionRowPadH,
        top: this.optionRowPadV,
        bottom: this.optionRowPadV
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius({
        topLeft: this.optionCardRadius,
        topRight: this.optionCardRadius,
        bottomLeft: this.isExpanded(node.folder) ? 0 : this.optionCardRadius,
        bottomRight: this.isExpanded(node.folder) ? 0 : this.optionCardRadius
      })
      .border({
        width: {
          top: 1, left: 1, right: 1,
          bottom: this.isExpanded(node.folder) ? 0 : 1
        },
        color: $r('app.color.card_border')
      })
      .clickEffect(this.rowClickEffect)
      .onClick(() => { this.onToggleFolder(node.folder); })

      if (this.isExpanded(node.folder)) {
        Column() {
          Divider()
            .strokeWidth(0.5)
            .color($r('app.color.card_border'))
            .margin({ left: 16, right: 16 })
          if (node.items.length > 0) {
            this.BookmarkItemsListBuilder({ folder: node.folder, items: node.items })
          }
          if (node.children.length > 0) {
            List() {
              ForEach(node.children, (child: BookmarkNavNode) => {
                ListItem() {
                  Column() {
                    this.BookmarkNavFolderBlock(child, depth + 1)
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                }
                .draggable(true)
                .swipeAction({
                  end: {
                    builder: () => { this.FolderSwipeEndBuilder(child.folder); }
                  }
                })
                .padding({ bottom: 10 })
              }, (child: BookmarkNavNode) => `${this.bookmarkSwipeRestoreKey}_${child.folder}`)
                .onMove((from: number, to: number) => {
                  this.onReorderChildFolders(node.folder, from, to);
                })
            }
            .width('100%')
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .backgroundColor($r('app.color.card_background'))
        // 每次展开都重新挂载该块，配合 transition 实现“下拉展开”动画
        .transition(
          TransitionEffect.OPACITY
            .combine(TransitionEffect.translate({ y: -8 }))
            .animation({ duration: 220, curve: Curve.EaseOut })
        )
        .borderRadius({
          topLeft: 0, topRight: 0,
          bottomLeft: this.optionCardRadius,
          bottomRight: this.optionCardRadius
        })
        .border({
          width: { top: 0, left: 1, right: 1, bottom: 1 },
          color: $r('app.color.card_border')
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: depth > 0 ? 8 : 0 })
  }

  @Builder
  private UnclassifiedFolderCard(group: BookmarkGroup) {
    Column() {
      Row() {
        Column() {
          Text(this.displayName(group.folder))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.contentPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`${group.items.length} 项`)
            .fontSize(14)
            .fontColor(this.contentSecondary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([$r('sys.color.icon_tertiary')])
          .rotate({ angle: this.isExpanded(group.folder) ? 90 : 0 })
          .animation({ duration: 400, curve: Curve.Friction })
      }
      .width('100%')
      .height(this.optionRowMinHeight)
      .padding({
        left: this.optionRowPadH,
        right: this.optionRowPadH,
        top: this.optionRowPadV,
        bottom: this.optionRowPadV
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius({
        topLeft: this.optionCardRadius,
        topRight: this.optionCardRadius,
        bottomLeft: this.isExpanded(group.folder) ? 0 : this.optionCardRadius,
        bottomRight: this.isExpanded(group.folder) ? 0 : this.optionCardRadius
      })
      .border({
        width: {
          top: 1, left: 1, right: 1,
          bottom: this.isExpanded(group.folder) ? 0 : 1
        },
        color: $r('app.color.card_border')
      })
      .clickEffect(this.rowClickEffect)
      .onClick(() => { this.onToggleFolder(group.folder); })

      if (this.isExpanded(group.folder)) {
        Column() {
          Divider()
            .strokeWidth(0.5)
            .color($r('app.color.card_border'))
            .margin({ left: 16, right: 16 })
          this.BookmarkItemsListBuilder(group)
        }
        .width('100%')
        .backgroundColor($r('app.color.card_background'))
        .transition(
          TransitionEffect.OPACITY
            .combine(TransitionEffect.translate({ y: -8 }))
            .animation({ duration: 220, curve: Curve.EaseOut })
        )
        .borderRadius({
          topLeft: 0, topRight: 0,
          bottomLeft: this.optionCardRadius,
          bottomRight: this.optionCardRadius
        })
        .border({
          width: { top: 0, left: 1, right: 1, bottom: 1 },
          color: $r('app.color.card_border')
        })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .clip(false)
  }

  @Builder
  private BookmarkListWithForest(forest: BookmarkNavForest) {
    List() {
      ForEach(this.buildRootSlotList(forest), (slot: BookmarkRootSlot) => {
        if (slot.slotType === 0) {
          ListItem() {
            Column() {
              Column() {
                this.BookmarkItemsListBuilder(forest.favBarGroup as BookmarkGroup)
              }
              .width('100%')
              .backgroundColor($r('app.color.card_background'))
              .borderRadius(this.optionCardRadius)
              .border({ width: 1, color: $r('app.color.card_border') })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .clip(false)
          }
          .draggable(true)
          .padding({ bottom: 10 })
        } else if (slot.slotType === 1) {
          ListItem() {
            Column() {
              this.BookmarkNavFolderBlock(slot.barRootNode as BookmarkNavNode, 0)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .clip(false)
          }
          .draggable(true)
          .swipeAction({
            end: {
              builder: () => {
                this.FolderSwipeEndBuilder((slot.barRootNode as BookmarkNavNode).folder);
              }
            }
          })
          .padding({ bottom: 10 })
        } else {
          ListItem() {
            this.UnclassifiedFolderCard(forest.unclassifiedGroup as BookmarkGroup)
          }
          .draggable(true)
          .swipeAction({
            end: {
              builder: () => { this.FolderSwipeEndBuilder('未分类'); }
            }
          })
          .padding({ bottom: 10 })
        }
      }, (slot: BookmarkRootSlot) => slot.key)
        .onMove((from: number, to: number) => {
          this.onReorderBookmarkGroups(from, to);
        })
    }
    .width('100%')
    .height('100%')
    // 顶栏已移入 Tab 内容区，不再用负 margin 与外层「标题+Swiper」对齐；由 BookmarkTabComp 的 Column.space 控制与标题间距
    .margin({
      top: 0,
      left: -BOOKMARK_LIST_DRAG_EDGE_BLEED_VP,
      right: -BOOKMARK_LIST_DRAG_EDGE_BLEED_VP,
      bottom: -BOOKMARK_LIST_SCROLL_EDGE_BOTTOM_VP
    })
    .padding({
      top: TITLE_CONTENT_GAP_VP,
      left: OPTION_ROW_PAD_H_VP + BOOKMARK_LIST_DRAG_EDGE_BLEED_VP,
      right: OPTION_ROW_PAD_H_VP + BOOKMARK_LIST_DRAG_EDGE_BLEED_VP,
      bottom: BOOKMARK_LIST_SCROLL_EDGE_BOTTOM_VP
    })
    .clip(false)
    // 列表主滚动在 List 上，Spring 需加在 List；外层 Scroll 同步设 Spring 以贴近「我的」页手感
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .id(`bm_list_${this.bookmarkSwipeRestoreKey}`)
  }

  build() {
    Column() {
      // 与「我的」页 BuildSettingsPage 一致：Scroll + edgeEffect(Spring)
      Scroll() {
        Column() {
          if (this.bookmarkGroups.length === 0) {
            // 空状态说明放在页面内，避免 .onAppear 在 Tab 切换 / 子树重建时重复触发 Toast
            Column({ space: 12 }) {
              Image($r('app.media.ic_bookmark'))
                .width(72)
                .height(72)
                .fillColor($r('sys.color.ohos_id_color_text_secondary'))
                .opacity(0.35)
              Text('点击右上角「+」菜单可新建或导入收藏')
                .fontSize(14)
                .fontColor(this.contentSecondary)
                .textAlign(TextAlign.Center)
                .width('100%')
                .lineHeight(22)
            }
            .width('100%')
            .constraintSize({ minHeight: '100%' })
            .justifyContent(FlexAlign.Center)
            .padding({ left: 32, right: 32, top: TITLE_CONTENT_GAP_VP })
          } else {
            this.BookmarkListWithForest(buildBookmarkNavForest(this.bookmarkGroups))
          }
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .layoutWeight(1)
    .clip(false)
    .id(`bm_page_${this.bookmarkRenderEpoch}`)
  }
}
