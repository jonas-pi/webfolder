import type { SearchEngineItem } from '../model/IndexTypes';

export interface SearchSettingsSheetProps {
  navChromeBg: ResourceColor;
  contentPrimary: Resource;
  contentSecondary: Resource;
  optionRowPadH: number;
  optionRowPadV: number;
  optionCardRadius: number;
  optionRowMinHeight: number;
  rowClickEffect: ClickEffect;
  searchEngines: Array<SearchEngineItem>;
  searchEngineIndex: number;
  searchBoxPosition: number;
  onBack: () => void;
  onSelectEngine: (idx: number) => void;
  onSelectSearchBoxPos: (pos: number) => void;
}

@Builder
export function BuildSearchSettingsSheet(props: SearchSettingsSheetProps) {
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
        Text('搜索设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(props.contentPrimary)
        Text('默认搜索引擎与搜索框位置')
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
        Text('默认搜索引擎')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')

        Grid() {
          ForEach(props.searchEngines, (item: SearchEngineItem, idx: number) => {
            GridItem() {
              Column({ space: 6 }) {
                Image(item.icon)
                  .width(30)
                  .height(30)
                  .objectFit(ImageFit.Contain)
                Text(item.name)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(props.searchEngineIndex === idx
                    ? $r('sys.color.ohos_id_color_emphasize')
                    : props.contentPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .height(78)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .borderRadius(props.optionCardRadius)
              .backgroundColor($r('app.color.card_background'))
              .border({
                width: 2,
                color: props.searchEngineIndex === idx
                  ? $r('sys.color.ohos_id_color_emphasize')
                  : $r('app.color.card_border')
              })
              .clickEffect(props.rowClickEffect)
              .onClick(() => { props.onSelectEngine(idx); })
            }
          }, (item: SearchEngineItem, idx: number) => `search_engine_pick_${idx}_${item.name}`)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .width('100%')

        Text('搜索框位置')
          .fontSize(13)
          .fontColor(props.contentSecondary)
          .width('100%')
          .margin({ top: 4 })

        Row({ space: 8 }) {
          Button('上')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(props.searchBoxPosition === 0 ? Color.White : props.contentPrimary)
            .backgroundColor(props.searchBoxPosition === 0 ?
              $r('sys.color.ohos_id_color_emphasize') :
              $r('app.color.card_background'))
            .border({
              width: 1,
              color: $r('app.color.card_border')
            })
            .borderRadius(12)
            .onClick(() => {
              props.onSelectSearchBoxPos(0);
            })
          Button('中')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(props.searchBoxPosition === 1 ? Color.White : props.contentPrimary)
            .backgroundColor(props.searchBoxPosition === 1 ?
              $r('sys.color.ohos_id_color_emphasize') :
              $r('app.color.card_background'))
            .border({
              width: 1,
              color: $r('app.color.card_border')
            })
            .borderRadius(12)
            .onClick(() => {
              props.onSelectSearchBoxPos(1);
            })
          Button('下')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(props.searchBoxPosition === 2 ? Color.White : props.contentPrimary)
            .backgroundColor(props.searchBoxPosition === 2 ?
              $r('sys.color.ohos_id_color_emphasize') :
              $r('app.color.card_background'))
            .border({
              width: 1,
              color: $r('app.color.card_border')
            })
            .borderRadius(12)
            .onClick(() => {
              props.onSelectSearchBoxPos(2);
            })
        }
        .width('100%')
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
