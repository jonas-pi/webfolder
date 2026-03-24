import { curves } from '@kit.ArkUI';

const DEFAULT_STAGGER_DURATION_MS: number = 220;
const DEFAULT_STAGGER_BASE_DELAY_MS: number = 30;
const DEFAULT_STAGGER_STEP_DELAY_MS: number = 10;

/**
 * 列表“错峰入场”：淡入 + 缩放 + springMotion，并支持按 idx 叠加 delay。
 * 适用于：Picker/下拉列表/菜单项逐个出现等场景。
 */
export function listScaleOpacityAppearTransition(
  itemIndex: number,
  durationMs: number = DEFAULT_STAGGER_DURATION_MS,
  baseDelayMs: number = DEFAULT_STAGGER_BASE_DELAY_MS,
  stepDelayMs: number = DEFAULT_STAGGER_STEP_DELAY_MS
): TransitionEffect {
  return TransitionEffect.OPACITY
    .combine(TransitionEffect.scale({ x: 0, y: 0 }))
    .animation({
      duration: durationMs,
      curve: curves.springMotion(0.5, 0.7, 0.6),
      delay: baseDelayMs + itemIndex * stepDelayMs
    });
}

/**
 * 图标进场动效（模仿 ClashBox：scale({0,0}) + rotate(360) + springMotion + 延迟错峰）
 */
export function iconScaleRotateAppearTransition(
  itemIndex: number,
  durationMs: number = 240,
  baseDelayMs: number = 40,
  stepDelayMs: number = 10
): TransitionEffect {
  return TransitionEffect.OPACITY
    .combine(TransitionEffect.scale({ x: 0, y: 0 }))
    .combine(TransitionEffect.rotate({ angle: 360 }))
    .animation({
      duration: durationMs,
      curve: curves.springMotion(0.5, 0.7, 0.6),
      delay: baseDelayMs + itemIndex * stepDelayMs
    });
}

/**
 * Sheet 内容入退出转场：不改变布局，只让面板整体“淡入+缩放”。
 * 注意：bindSheet 内部也可能有默认动画；如果你后续发现双重动画重叠，我再帮你按实际情况调参/关闭其中一层。
 */
export function sheetEnterExitTransition(durationMs: number = 240): TransitionEffect {
  // 半模态场景：缩放幅度要更轻，否则标题/返回按钮在动画过程中可能出现越界裁切。
  const enterEffect: TransitionEffect = TransitionEffect.OPACITY
    .combine(TransitionEffect.scale({ x: 0.98, y: 0.98 }))
    .animation({
      duration: durationMs,
      curve: curves.springMotion(0.55, 0.7, 0.65),
      delay: 0
    });

  const exitEffect: TransitionEffect = TransitionEffect.OPACITY
    .combine(TransitionEffect.scale({ x: 0.97, y: 0.97 }))
    .animation({
      duration: durationMs,
      curve: curves.springMotion(0.55, 0.7, 0.65),
      delay: 0
    });

  return TransitionEffect.asymmetric(enterEffect, exitEffect);
}

