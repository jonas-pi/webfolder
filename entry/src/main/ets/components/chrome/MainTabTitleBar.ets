import { TITLE_BAR_FONT_SIZE, TITLE_BAR_HEIGHT_VP } from '../../constants/AppLayout';

/** 无尾部控件时的占位 Builder（@BuilderParam 默认值） */
@Builder
export function mainTabTitleBarEmptyTrailing(): void {
}

/**
 * 主 Tab 顶栏标题行（与 ClashBox 各子页「标题 + 内容」分层一致：标题属于当前 Tab 内容区）。
 * 可选尾部：使用子组件块 `MainTabTitleBar({ title }) { ... }`；
 * 勿用 `trailing: this.xxx` 传 @Builder 引用（部分真机上会为 undefined，导致 this.trailing() 崩溃）。
 */
@Component
export struct MainTabTitleBar {
  @Prop title: string = '';
  @BuilderParam trailing: () => void = mainTabTitleBarEmptyTrailing;
  @Consume('statusBarInsetVp') statusBarInsetVp: number = 38;
  /** 与 Index 一致：true 时标题栏副背景向上延伸至状态栏区域 */
  @Consume('immersiveEdgeLight') immersiveEdgeLight: boolean = true;

  build() {
    Column() {
      if (this.immersiveEdgeLight) {
        Column()
          .width('100%')
          .height(this.statusBarInsetVp)
      }
      Row() {
        Text(this.title)
          .fontSize(TITLE_BAR_FONT_SIZE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
        this.trailing()
      }
      .width('100%')
      .height(TITLE_BAR_HEIGHT_VP)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}
