import type { BookmarkItem } from '../model/IndexTypes';
import type { BookmarkInfo, SyncDataInfo } from '../model/BookmarkSyncTypes';
import { RootBookmarksType } from '../model/BookmarkSyncTypes';
import { normalizeBookmarkFolderPath, splitBookmarkFolderSegments } from './BookmarkUtils';

/** 写入 SyncDataInfo.version，与 HM 工程版本解耦，仅表示载荷结构版本 */
const HM_BOOKMARK_SYNC_SCHEMA_VERSION: string = '1.0.0';

const HM_FOLDER_TOOLBAR: string = '收藏夹栏';
const HM_FOLDER_UNFILED: string = '未分类';
const HM_FOLDER_MOBILE: string = '移动设备';
/** 对应浏览器「书签菜单」根下直接放置的链接，与 BookmarkHub MenuFolder 对齐 */
const HM_FOLDER_MENU_DIRECT: string = '书签菜单';

type RootBucket = 'toolbar' | 'unfiled' | 'mobile' | 'menu';

/**
 * 判断扁平书签应归入 BookmarkHub 的哪一个标准根（Menu / Toolbar / Unfiled / Mobile）。
 */
function rootBucketForItem(item: BookmarkItem): RootBucket {
  const f: string = normalizeBookmarkFolderPath(item.folder);
  if (f === HM_FOLDER_TOOLBAR || f.startsWith(`${HM_FOLDER_TOOLBAR} / `)) {
    return 'toolbar';
  }
  if (f === HM_FOLDER_UNFILED || f.startsWith(`${HM_FOLDER_UNFILED} / `)) {
    return 'unfiled';
  }
  if (f === HM_FOLDER_MOBILE || f.startsWith(`${HM_FOLDER_MOBILE} / `)) {
    return 'mobile';
  }
  return 'menu';
}

function toolbarRelSegments(folder: string): string[] {
  const f: string = normalizeBookmarkFolderPath(folder);
  if (f === HM_FOLDER_TOOLBAR) {
    return [];
  }
  const prefix: string = `${HM_FOLDER_TOOLBAR} / `;
  if (f.startsWith(prefix)) {
    return splitBookmarkFolderSegments(f.slice(prefix.length));
  }
  return [];
}

function unfiledRelSegments(folder: string): string[] {
  const f: string = normalizeBookmarkFolderPath(folder);
  if (f === HM_FOLDER_UNFILED) {
    return [];
  }
  const prefix: string = `${HM_FOLDER_UNFILED} / `;
  if (f.startsWith(prefix)) {
    return splitBookmarkFolderSegments(f.slice(prefix.length));
  }
  return [];
}

function mobileRelSegments(folder: string): string[] {
  const f: string = normalizeBookmarkFolderPath(folder);
  if (f === HM_FOLDER_MOBILE) {
    return [];
  }
  const prefix: string = `${HM_FOLDER_MOBILE} / `;
  if (f.startsWith(prefix)) {
    return splitBookmarkFolderSegments(f.slice(prefix.length));
  }
  return [];
}

/**
 * Menu 根下：HM 原先用顶层路径名（如「工作」）表示菜单栏下文件夹，与「书签菜单」前缀并列。
 */
function menuRelSegments(folder: string): string[] {
  const f: string = normalizeBookmarkFolderPath(folder);
  if (f === HM_FOLDER_MENU_DIRECT) {
    return [];
  }
  const prefix: string = `${HM_FOLDER_MENU_DIRECT} / `;
  if (f.startsWith(prefix)) {
    return splitBookmarkFolderSegments(f.slice(prefix.length));
  }
  return splitBookmarkFolderSegments(f);
}

/**
 * 在某一 Hub 根下按相对路径插入文件夹链，并在末级挂上带 url 的书签叶子。
 */
function addFlatItemUnderHubRoot(root: BookmarkInfo, relSegs: string[], title: string, url: string): void {
  let cur: BookmarkInfo = root;
  if (cur.children === undefined) {
    cur.children = [];
  }
  let di: number = 0;
  while (di < relSegs.length) {
    const seg: string = relSegs[di];
    let next: BookmarkInfo | null = null;
    let ci: number = 0;
    while (ci < cur.children!.length) {
      const ch: BookmarkInfo = cur.children![ci];
      const isFolder: boolean = ch.url === undefined || ch.url.length === 0;
      if (isFolder && ch.title === seg) {
        next = ch;
        break;
      }
      ci++;
    }
    if (next === null) {
      next = { title: seg, children: [] };
      cur.children!.push(next);
    }
    cur = next;
    if (cur.children === undefined) {
      cur.children = [];
    }
    di++;
  }
  const leaf: BookmarkInfo = { title: title, url: url };
  cur.children!.push(leaf);
}

/**
 * 将 HM 扁平列表转为与 BookmarkHub 一致的四个根节点（顺序：Menu、Toolbar、Unfiled、Mobile）。
 */
function buildHubRootsFromFlatItems(items: Array<BookmarkItem>): BookmarkInfo[] {
  const menuRoot: BookmarkInfo = { title: RootBookmarksType.MenuFolder, children: [] };
  const toolbarRoot: BookmarkInfo = { title: RootBookmarksType.ToolbarFolder, children: [] };
  const unfiledRoot: BookmarkInfo = { title: RootBookmarksType.UnfiledFolder, children: [] };
  const mobileRoot: BookmarkInfo = { title: RootBookmarksType.MobileFolder, children: [] };

  let i: number = 0;
  while (i < items.length) {
    const it: BookmarkItem = items[i];
    const bucket: RootBucket = rootBucketForItem(it);
    if (bucket === 'toolbar') {
      addFlatItemUnderHubRoot(toolbarRoot, toolbarRelSegments(it.folder), it.title, it.url);
    } else if (bucket === 'unfiled') {
      addFlatItemUnderHubRoot(unfiledRoot, unfiledRelSegments(it.folder), it.title, it.url);
    } else if (bucket === 'mobile') {
      addFlatItemUnderHubRoot(mobileRoot, mobileRelSegments(it.folder), it.title, it.url);
    } else {
      addFlatItemUnderHubRoot(menuRoot, menuRelSegments(it.folder), it.title, it.url);
    }
    i++;
  }

  return [menuRoot, toolbarRoot, unfiledRoot, mobileRoot];
}

/**
 * 供持久化与 Gist 导出：生成顶层 SyncDataInfo（字段名与 BookmarkHub 一致）。
 */
/**
 * @param preserveCreateDate 若传入且大于 0，则沿用该时间戳（本地改书签但不抬升版本，便于与 Gist 上 createDate 比较做自动拉取）
 */
export function flatItemsToSyncData(items: Array<BookmarkItem>, preserveCreateDate?: number): SyncDataInfo {
  let ts: number = Date.now();
  if (preserveCreateDate !== undefined && preserveCreateDate > 0) {
    ts = preserveCreateDate;
  }
  const sync: SyncDataInfo = {
    browser: 'HarmonyOS/HM',
    version: HM_BOOKMARK_SYNC_SCHEMA_VERSION,
    createDate: ts,
    bookmarks: buildHubRootsFromFlatItems(items)
  };
  return sync;
}

/**
 * 将 Gist / 本地文件解析结果转为 SyncDataInfo：支持旧版「纯数组」与新版对象。
 */
export function bookmarkPayloadFromParsedJson(parsed: object | null): SyncDataInfo | null {
  if (parsed === null) {
    return null;
  }
  if (Array.isArray(parsed)) {
    return flatItemsToSyncData(parsed as BookmarkItem[]);
  }
  const rec = parsed as Record<string, Object | null | undefined>;
  const bm: Object | null | undefined = rec['bookmarks'];
  if (bm !== undefined && bm !== null && Array.isArray(bm)) {
    const sync: SyncDataInfo = {
      browser: (rec['browser'] as string) ?? 'HarmonyOS/HM',
      version: (rec['version'] as string) ?? HM_BOOKMARK_SYNC_SCHEMA_VERSION,
      createDate: (rec['createDate'] as number) ?? Date.now(),
      bookmarks: bm as BookmarkInfo[]
    };
    return sync;
  }
  return null;
}

function emptyChildRoot(title: string): BookmarkInfo {
  return { title: title, children: [] };
}

/**
 * 保证四个标准根齐全且顺序固定，缺失则补空 children，避免扩展端解析异常。
 */
export function normalizeSyncRootArray(roots: BookmarkInfo[] | undefined): BookmarkInfo[] {
  const map: Map<string, BookmarkInfo> = new Map();
  let i: number = 0;
  while (i < (roots ?? []).length) {
    const r: BookmarkInfo = roots![i];
    if (r.title !== undefined && r.title.length > 0) {
      map.set(r.title, r);
    }
    i++;
  }
  const order: string[] = [
    RootBookmarksType.MenuFolder,
    RootBookmarksType.ToolbarFolder,
    RootBookmarksType.UnfiledFolder,
    RootBookmarksType.MobileFolder
  ];
  const out: BookmarkInfo[] = [];
  let oi: number = 0;
  while (oi < order.length) {
    const key: string = order[oi];
    const existing: BookmarkInfo | undefined = map.get(key);
    if (existing !== undefined) {
      out.push(existing);
    } else {
      out.push(emptyChildRoot(key));
    }
    oi++;
  }
  return out;
}

/**
 * 遍历某一 Hub 根下子树，还原为 HM 使用的 folder 路径 + 扁平书签。
 * @param baseHmFolder 该根在 HM 中对应的顶层路径（空串表示由 directOnlyFolder 承接「直接挂在根下」的链接）
 * @param directOnlyFolder 仅当 baseHmFolder 为空且遇到带 url 的直连子节点时使用（Menu 根）
 */
function walkHubChildrenToFlat(
  children: BookmarkInfo[] | undefined,
  baseHmFolder: string,
  directOnlyFolder: string,
  out: Array<BookmarkItem>
): void {
  const list: BookmarkInfo[] = children ?? [];
  let i: number = 0;
  while (i < list.length) {
    const c: BookmarkInfo = list[i];
    const hasUrl: boolean = c.url !== undefined && c.url.length > 0;
    if (hasUrl) {
      const folderPath: string = baseHmFolder.length > 0 ? baseHmFolder : directOnlyFolder;
      out.push({ folder: folderPath, title: c.title, url: c.url as string });
    } else {
      const subBase: string = baseHmFolder.length === 0 ? c.title : `${baseHmFolder} / ${c.title}`;
      walkHubChildrenToFlat(c.children, subBase, directOnlyFolder, out);
    }
    i++;
  }
}

/**
 * Hub 四根 → HM 扁平 BookmarkItem[]（顺序：菜单、工具栏、其它、移动，与 buildHubRootsFromFlatItems 对称）。
 */
export function bookmarkHubRootsToFlatItems(roots: BookmarkInfo[] | undefined): Array<BookmarkItem> {
  const norm: BookmarkInfo[] = normalizeSyncRootArray(roots);
  const out: Array<BookmarkItem> = [];
  walkHubChildrenToFlat(norm[0].children, '', HM_FOLDER_MENU_DIRECT, out);
  walkHubChildrenToFlat(norm[1].children, HM_FOLDER_TOOLBAR, '', out);
  walkHubChildrenToFlat(norm[2].children, HM_FOLDER_UNFILED, '', out);
  walkHubChildrenToFlat(norm[3].children, HM_FOLDER_MOBILE, '', out);
  return out;
}

/**
 * 从 SyncDataInfo 仅取出扁平列表（UI 层仍用 BookmarkGroup 逻辑）。
 */
export function flatItemsFromSyncData(sync: SyncDataInfo): Array<BookmarkItem> {
  return bookmarkHubRootsToFlatItems(sync.bookmarks);
}
