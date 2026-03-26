export const SHEET_ROUTE_NONE: number = 0;
export const SHEET_ROUTE_BACKGROUND: number = 1;
export const SHEET_ROUTE_SEARCH_SETTINGS: number = 2;
export const SHEET_ROUTE_NEW_BOOKMARK: number = 3;
export const SHEET_ROUTE_RENAME_FOLDER: number = 4;
export const SHEET_ROUTE_MOVE_BOOKMARK: number = 5;
export const SHEET_ROUTE_EDIT_BOOKMARK: number = 6;
/** 与 AppLayout.SHEET_GIST_SYNC 对应 */
export const SHEET_ROUTE_GIST_SYNC: number = 8;
export const SHEET_ROUTE_FALLBACK_CLOSE: number = 9;

export function resolveSheetRoute(sheetMode: number, sheetVisible: boolean): number {
  if (sheetMode === 1) {
    return SHEET_ROUTE_BACKGROUND;
  }
  if (sheetMode === 2) {
    return SHEET_ROUTE_SEARCH_SETTINGS;
  }
  if (sheetMode === 3) {
    return SHEET_ROUTE_NEW_BOOKMARK;
  }
  if (sheetMode === 4) {
    return SHEET_ROUTE_RENAME_FOLDER;
  }
  if (sheetMode === 5) {
    return SHEET_ROUTE_MOVE_BOOKMARK;
  }
  if (sheetMode === 6) {
    return SHEET_ROUTE_EDIT_BOOKMARK;
  }
  if (sheetMode === 7) {
    return SHEET_ROUTE_GIST_SYNC;
  }
  if (sheetVisible) {
    return SHEET_ROUTE_FALLBACK_CLOSE;
  }
  return SHEET_ROUTE_NONE;
}
