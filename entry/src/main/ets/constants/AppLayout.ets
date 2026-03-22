// ── Sheet 状态值（sheetMode 字段枚举） ─────────────────────────────────────
/** 0 = 无面板 */
export const SHEET_NONE: number = 0;
export const SHEET_BACKGROUND: number = 1;
export const SHEET_SEARCH_SETTINGS: number = 2;
export const SHEET_NEW_BOOKMARK: number = 3;
export const SHEET_RENAME_FOLDER: number = 4;
export const SHEET_MOVE_BOOKMARK: number = 5;
export const SHEET_EDIT_BOOKMARK: number = 6;

// ── 业务限制 ─────────────────────────────────────────────────────────────────
/** 书签文件夹路径层级上限（与 Edge「文件夹 / 子文件夹」一致） */
export const BOOKMARK_FOLDER_MAX_DEPTH: number = 9;

// ── 时序 ──────────────────────────────────────────────────────────────────────
/** Sheet onWillDismiss 后延迟清空 sheetMode（让关闭动画走完），与「再次打开」互斥 */
export const SHEET_MODE_RESET_DELAY_MS: number = 420;
/** 主 Tab 切换动画时长（ms） */
export const TAB_SWIPE_DURATION_MS: number = 300;
/** 底栏图标选中态动画时长（短于 Tab 切换，避免叠加重绘） */
export const NAV_TAB_ICON_ANIM_MS: number = 160;
/** 收藏夹书签行出现动画时长 */
export const BOOKMARK_NODE_APPEAR_MS: number = 350;
/** 系统胶囊 Toast 短/长持续时长 */
export const TOAST_DURATION_SHORT_MS: number = 2000;
export const TOAST_DURATION_LONG_MS: number = 4500;

// ── 侧滑 ──────────────────────────────────────────────────────────────────────
/** 左滑圆形按钮尺寸（vp） */
export const SWIPE_ACTION_ICON_BTN_VP: number = 48;
/** 侧滑按钮进出场横向位移（vp）：从右侧远处滑入/滑出，消除残留 */
export const SWIPE_ACTION_SLIDE_VP: number = 320;

// ── 布局尺寸 ──────────────────────────────────────────────────────────────────
/** 新建收藏：文件夹行最小高度（vp） */
export const NEW_BOOKMARK_FOLDER_ROW_HEIGHT_VP: number = 44;
/** 顶栏标题区高度（对齐系统 TAB_CONTENT_TITLE_HEIGHT） */
export const TITLE_BAR_HEIGHT_VP: number = 56;
/** 顶栏主标题字号 */
export const TITLE_BAR_FONT_SIZE: number = 30;
/** 底栏图标区高度（可点按内容区） */
export const BOTTOM_NAV_BAR_HEIGHT_VP: number = 68;
/** 底部手势条（小白条）安全避让高度；总栏高 = 内容区 + 此值 */
export const BOTTOM_INDICATOR_SAFE_VP: number = 24;
/** 标题栏与主内容（Swiper）之间的间距 */
export const TITLE_CONTENT_GAP_VP: number = 10;
/**
 * 书签 List 顶部 padding（与 marginTop = -TITLE_CONTENT_GAP_VP 成对）。
 * 净效果：文件夹首行与标题栏间距仍为 TITLE_CONTENT_GAP_VP，且列表仍可向上滚入标题下间隙。
 */
export const BOOKMARK_LIST_TOP_PADDING_VP: number = TITLE_CONTENT_GAP_VP * 2;
/**
 * 书签列表底部可滚入「内容与底栏」区域的高度（与原 List bottom 8 + 外层 Column bottom 16 一致），
 * 仅用于 margin/padding 抵消，不改变默认首末项位置。
 */
export const BOOKMARK_LIST_SCROLL_EDGE_BOTTOM_VP: number = 24;
/**
 * 长按拖动文件夹排序时缩放外溢：List 左右负 margin + 等量 padding，扩大可绘制区，
 * 避免卡片略放大时被 List 左右边缘裁切（与 OPTION_ROW_PAD_H_VP 叠加为水平内边距）。
 */
export const BOOKMARK_LIST_DRAG_EDGE_BLEED_VP: number = 12;
/** 分组卡片统一圆角 */
export const OPTION_CARD_RADIUS_VP: number = 24;
/** 双行主副标题行最小高度 */
export const OPTION_ROW_MIN_HEIGHT_VP: number = 64;
/** 行内左右内边距 */
export const OPTION_ROW_PAD_H_VP: number = 16;
/** 行内上下内边距 */
export const OPTION_ROW_PAD_V_VP: number = 8;
/** 含 Slider 的卡片上下内边距 */
export const OPTION_SLIDER_CARD_PAD_VP: number = 12;
// ── 默认值 ────────────────────────────────────────────────────────────────────
/** 默认背景虚化强度 */
export const DEFAULT_BACKGROUND_BLUR: number = 24;
/** 默认背景明暗（50 = 不叠加任何遮罩） */
export const DEFAULT_BACKGROUND_BRIGHTNESS: number = 50;
