import type {
  BookmarkGroup, BookmarkItem, BookmarkNavForest, BookmarkNavNode, FolderTreeNode
} from '../model/IndexTypes';

export function bookmarkCollectDistinctFolderPaths(groups: Array<BookmarkGroup>): Array<string> {
  const set: Set<string> = new Set<string>();
  let gi: number = 0;
  while (gi < groups.length) {
    const f: string = groups[gi].folder.trim();
    if (f.length > 0) {
      set.add(f);
    }
    gi++;
  }
  const arr: Array<string> = Array.from(set);
  arr.sort((a: string, b: string) => {
    if (a === '未分类') {
      return -1;
    }
    if (b === '未分类') {
      return 1;
    }
    return a.localeCompare(b, 'zh-CN');
  });
  return arr;
}

export function splitBookmarkFolderSegments(raw: string): Array<string> {
  const trimmed: string = raw.trim();
  if (trimmed.length === 0) {
    return [];
  }
  const parts: Array<string> = trimmed.split(/\s*\/\s*/);
  const out: Array<string> = [];
  let i: number = 0;
  while (i < parts.length) {
    const t: string = parts[i].trim();
    if (t.length > 0) {
      out.push(t);
    }
    i++;
  }
  return out;
}

export function normalizeBookmarkFolderPath(raw: string): string {
  const segs: Array<string> = splitBookmarkFolderSegments(raw);
  if (segs.length === 0) {
    return '';
  }
  return segs.join(' / ');
}

export function bookmarkFolderPathDepthFromRaw(raw: string): number {
  return splitBookmarkFolderSegments(raw).length;
}

export function folderDepthFromFullPath(path: string): number {
  return splitBookmarkFolderSegments(path).length;
}

function findOrCreateFolderTreeChild(
  siblings: Array<FolderTreeNode>,
  fullPath: string,
  segmentLabel: string
): FolderTreeNode {
  let i: number = 0;
  while (i < siblings.length) {
    if (siblings[i].fullPath === fullPath) {
      return siblings[i];
    }
    i++;
  }
  const node: FolderTreeNode = { fullPath: fullPath, segmentLabel: segmentLabel, children: [] };
  siblings.push(node);
  return node;
}

function insertFolderPathIntoTree(tree: Array<FolderTreeNode>, path: string): void {
  const segs: Array<string> = splitBookmarkFolderSegments(path);
  if (segs.length === 0) {
    return;
  }
  let currentLevel: Array<FolderTreeNode> = tree;
  let acc: string = '';
  let si: number = 0;
  while (si < segs.length) {
    const seg: string = segs[si];
    acc = acc.length === 0 ? seg : `${acc} / ${seg}`;
    const node: FolderTreeNode = findOrCreateFolderTreeChild(currentLevel, acc, seg);
    currentLevel = node.children;
    si++;
  }
}

function sortFolderTreeNodes(nodes: Array<FolderTreeNode>, isRoot: boolean): void {
  if (isRoot) {
    nodes.sort((a: FolderTreeNode, b: FolderTreeNode) => {
      if (a.fullPath === '未分类') {
        return -1;
      }
      if (b.fullPath === '未分类') {
        return 1;
      }
      return a.segmentLabel.localeCompare(b.segmentLabel, 'zh-CN');
    });
  } else {
    nodes.sort((a: FolderTreeNode, b: FolderTreeNode) => {
      return a.segmentLabel.localeCompare(b.segmentLabel, 'zh-CN');
    });
  }
  let i: number = 0;
  while (i < nodes.length) {
    sortFolderTreeNodes(nodes[i].children, false);
    i++;
  }
}

export function buildFolderTreeFromPaths(paths: Array<string>): Array<FolderTreeNode> {
  const roots: Array<FolderTreeNode> = [];
  let pi: number = 0;
  while (pi < paths.length) {
    insertFolderPathIntoTree(roots, paths[pi]);
    pi++;
  }
  sortFolderTreeNodes(roots, true);
  return roots;
}

/**
 * 与 buildFolderTreeFromPaths 相同，但根节点保持传入顺序（与主界面文件夹排列一致），
 * 只对每个节点的子节点做字典序排序。
 * 用于新建/移动书签的文件夹选择器，确保顺序与主界面固定一致。
 */
export function buildFolderTreeFromPathsOrdered(paths: Array<string>): Array<FolderTreeNode> {
  const roots: Array<FolderTreeNode> = [];
  let pi: number = 0;
  while (pi < paths.length) {
    insertFolderPathIntoTree(roots, paths[pi]);
    pi++;
  }
  // 根节点保持插入顺序，仅递归排序子节点
  let ri: number = 0;
  while (ri < roots.length) {
    sortFolderTreeNodes(roots[ri].children, false);
    ri++;
  }
  return roots;
}

export function normalizeBookmarkUrlInput(raw: string): string {
  let t: string = raw.trim();
  if (t.length === 0) {
    return '';
  }
  if (!t.startsWith('http://') && !t.startsWith('https://')) {
    t = `https://${t}`;
  }
  return t;
}

export function validateBookmarkUrlReasonable(url: string): string | null {
  const u: string = url.trim();
  if (u.length === 0) {
    return '请输入网址';
  }
  if (/\s/.test(u)) {
    return '网址中不能包含空格';
  }
  const matched: RegExpExecArray | null = /^https?:\/\/([^/?#\s]+)/i.exec(u);
  if (matched === null) {
    return '请使用 http:// 或 https:// 开头（可只填域名，将自动补全）';
  }
  const authority: string = matched[1];
  if (authority.length === 0) {
    return '请填写域名或主机地址（例如 example.com）';
  }
  if (/[<>"']/.test(authority)) {
    return '网址格式不正确';
  }
  return null;
}

export function collectAllBookmarksFromGroups(groups: Array<BookmarkGroup>): Array<BookmarkItem> {
  const allItems: Array<BookmarkItem> = [];
  let gi: number = 0;
  while (gi < groups.length) {
    let ii: number = 0;
    while (ii < groups[gi].items.length) {
      allItems.push(groups[gi].items[ii]);
      ii += 1;
    }
    gi += 1;
  }
  return allItems;
}

export function decodeHtml(text: string): string {
  let decoded: string = text;
  decoded = decoded.replaceAll('&amp;', '&');
  decoded = decoded.replaceAll('&lt;', '<');
  decoded = decoded.replaceAll('&gt;', '>');
  decoded = decoded.replaceAll('&quot;', '"');
  decoded = decoded.replaceAll('&#39;', '\'');
  return decoded;
}

export function extractHost(url: string): string {
  const matched: RegExpExecArray | null = /^https?:\/\/([^\/?#]+)/i.exec(url);
  if (matched === null || matched.length < 2) {
    return '';
  }
  return matched[1].toLowerCase();
}

export function faviconUrl(url: string): string {
  const host: string = extractHost(url);
  if (host.length === 0) {
    return '';
  }
  return `https://www.google.com/s2/favicons?domain=${host}&sz=64`;
}

export function titleInitial(title: string): string {
  const trimmed: string = title.trim();
  if (trimmed.length === 0) {
    return '?';
  }
  return trimmed.substring(0, 1).toUpperCase();
}

export function parseBookmarksFromHtml(html: string): Array<BookmarkItem> {
  const result: Array<BookmarkItem> = [];
  const lines: Array<string> = html.split('\n');
  const folderStack: Array<string> = [];
  let pendingFolder: string = '';
  const h3Regex: RegExp = /<H3[^>]*>(.*?)<\/H3>/i;
  const anchorRegex: RegExp = /<A\s+[^>]*HREF="([^"]+)"[^>]*>(.*?)<\/A>/i;

  let index: number = 0;
  while (index < lines.length) {
    const line: string = lines[index].trim();
    const upperLine: string = line.toUpperCase();

    const h3Match: RegExpExecArray | null = h3Regex.exec(line);
    if (h3Match !== null) {
      pendingFolder = decodeHtml(h3Match[1]).trim();
      index += 1;
      continue;
    }

    if (upperLine.startsWith('<DL') && pendingFolder.length > 0) {
      folderStack.push(pendingFolder);
      pendingFolder = '';
      index += 1;
      continue;
    }

    if (upperLine.includes('</DL>')) {
      if (folderStack.length > 0) {
        folderStack.pop();
      }
      index += 1;
      continue;
    }

    const anchorMatch: RegExpExecArray | null = anchorRegex.exec(line);
    if (anchorMatch !== null) {
      const rawUrl: string = decodeHtml(anchorMatch[1]).trim();
      const rawTitle: string = decodeHtml(anchorMatch[2]).trim();
      if ((rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) && rawTitle.length > 0) {
        const folderName: string = folderStack.length > 0 ? folderStack.join(' / ') : '未分类';
        result.push({ folder: folderName, title: rawTitle, url: rawUrl });
      }
      index += 1;
      continue;
    }
    index += 1;
  }
  return result;
}

export function groupBookmarks(items: Array<BookmarkItem>): Array<BookmarkGroup> {
  const groups: Array<BookmarkGroup> = [];
  let index: number = 0;
  while (index < items.length) {
    const item: BookmarkItem = items[index];
    let found: BookmarkGroup | null = null;
    let gIndex: number = 0;
    while (gIndex < groups.length) {
      if (groups[gIndex].folder === item.folder) {
        found = groups[gIndex];
        break;
      }
      gIndex += 1;
    }
    if (found === null) {
      const newGroup: BookmarkGroup = { folder: item.folder, items: [] };
      newGroup.items.push(item);
      groups.push(newGroup);
    } else {
      found.items.push(item);
    }
    index += 1;
  }
  return groups;
}

/**
 * 克隆分组树（新数组、新 items 数组、新 BookmarkItem 对象）。
 * ArkTS 对 @State 数组常为引用比较：若仍指向同一批 BookmarkItem，第二次起可能不触发子组件刷新。
 */
export function cloneBookmarkGroups(groups: Array<BookmarkGroup>): Array<BookmarkGroup> {
  const out: Array<BookmarkGroup> = [];
  let gi: number = 0;
  while (gi < groups.length) {
    const g: BookmarkGroup = groups[gi];
    const itemsCopy: Array<BookmarkItem> = [];
    let ii: number = 0;
    while (ii < g.items.length) {
      const it: BookmarkItem = g.items[ii];
      itemsCopy.push({ folder: it.folder, title: it.title, url: it.url });
      ii++;
    }
    out.push({ folder: g.folder, items: itemsCopy });
    gi++;
  }
  return out;
}

/**
 * 按 `folderOrderHint` 中文件夹顺序输出分组（与主界面拖拽顺序、导入顺序一致），
 * 同一文件夹内书签顺序与 `items` 中出现顺序一致。
 * hint 中不存在的文件夹（新建）按在 `items` 中首次出现的顺序接在末尾。
 */
export function groupBookmarksPreserveFolderOrder(
  items: Array<BookmarkItem>,
  folderOrderHint: Array<string>
): Array<BookmarkGroup> {
  const firstOrder: Array<string> = [];
  const bucketFor: Array<Array<BookmarkItem>> = [];
  let ii: number = 0;
  while (ii < items.length) {
    const f: string = items[ii].folder;
    let ix: number = 0;
    let foundIdx: number = -1;
    while (ix < firstOrder.length) {
      if (firstOrder[ix] === f) {
        foundIdx = ix;
        break;
      }
      ix++;
    }
    if (foundIdx < 0) {
      firstOrder.push(f);
      const b: Array<BookmarkItem> = [];
      b.push(items[ii]);
      bucketFor.push(b);
    } else {
      bucketFor[foundIdx].push(items[ii]);
    }
    ii++;
  }

  const out: Array<BookmarkGroup> = [];
  const consumed: Array<boolean> = [];
  let ci: number = 0;
  while (ci < firstOrder.length) {
    consumed.push(false);
    ci++;
  }

  let h: number = 0;
  while (h < folderOrderHint.length) {
    const folderName: string = folderOrderHint[h];
    let fo: number = 0;
    while (fo < firstOrder.length) {
      if (firstOrder[fo] === folderName && !consumed[fo] && bucketFor[fo].length > 0) {
        out.push({ folder: folderName, items: bucketFor[fo] });
        consumed[fo] = true;
        break;
      }
      fo++;
    }
    h++;
  }

  let fo2: number = 0;
  while (fo2 < firstOrder.length) {
    if (!consumed[fo2] && bucketFor[fo2].length > 0) {
      out.push({ folder: firstOrder[fo2], items: bucketFor[fo2] });
    }
    fo2++;
  }

  return out;
}

const BAR_PREFIX: string = '收藏夹栏 / ';

/**
 * 拖拽排序用：同一「顶层文件夹块」的根键（收藏夹栏、未分类为自身；收藏夹栏 / a/b 与 /a/c 同属 a）。
 */
export function bookmarkRootKeyForFolder(folder: string): string {
  if (folder === '收藏夹栏' || folder === '未分类') {
    return folder;
  }
  if (folder.startsWith(BAR_PREFIX)) {
    const segs: Array<string> = splitBookmarkFolderSegments(folder.slice(BAR_PREFIX.length));
    if (segs.length > 0) {
      return BAR_PREFIX + segs[0];
    }
  }
  return folder;
}

function insertGroupIntoBarNavRoots(roots: Array<BookmarkNavNode>, group: BookmarkGroup): void {
  const f: string = group.folder;
  if (!f.startsWith(BAR_PREFIX)) {
    return;
  }
  const rest: string = f.slice(BAR_PREFIX.length);
  const segs: Array<string> = splitBookmarkFolderSegments(rest);
  if (segs.length === 0) {
    return;
  }
  const rootKey: string = BAR_PREFIX + segs[0];
  let rootNode: BookmarkNavNode | null = null;
  let ri: number = 0;
  while (ri < roots.length) {
    if (roots[ri].folder === rootKey) {
      rootNode = roots[ri];
      break;
    }
    ri++;
  }
  if (rootNode === null) {
    rootNode = { folder: rootKey, segmentLabel: segs[0], items: [], children: [] };
    roots.push(rootNode);
  }
  if (segs.length === 1) {
    rootNode.items = group.items;
    return;
  }
  let current: BookmarkNavNode = rootNode;
  let pathAcc: string = rootKey;
  let si: number = 1;
  while (si < segs.length) {
    pathAcc = `${pathAcc} / ${segs[si]}`;
    let child: BookmarkNavNode | null = null;
    let ci: number = 0;
    while (ci < current.children.length) {
      if (current.children[ci].folder === pathAcc) {
        child = current.children[ci];
        break;
      }
      ci++;
    }
    if (child === null) {
      child = { folder: pathAcc, segmentLabel: segs[si], items: [], children: [] };
      current.children.push(child);
    }
    if (si === segs.length - 1) {
      child.items = group.items;
    }
    current = child;
    si++;
  }
}

/**
 * 将扁平 bookmarkGroups 转为导航森林：「收藏夹栏 /」下多级路径折叠为树，子文件夹显示在父文件夹内。
 */
export function buildBookmarkNavForest(groups: Array<BookmarkGroup>): BookmarkNavForest {
  let favBarGroup: BookmarkGroup | null = null;
  let unclassifiedGroup: BookmarkGroup | null = null;
  const barFolderRoots: Array<BookmarkNavNode> = [];
  let gi: number = 0;
  while (gi < groups.length) {
    const g: BookmarkGroup = groups[gi];
    if (g.folder === '收藏夹栏') {
      favBarGroup = g;
    } else if (g.folder === '未分类') {
      unclassifiedGroup = g;
    } else if (g.folder.startsWith(BAR_PREFIX)) {
      insertGroupIntoBarNavRoots(barFolderRoots, g);
    } else {
      barFolderRoots.push({
        folder: g.folder,
        segmentLabel: g.folder,
        items: g.items,
        children: []
      });
    }
    gi++;
  }
  return { favBarGroup: favBarGroup, unclassifiedGroup: unclassifiedGroup, barFolderRoots: barFolderRoots };
}

interface ForestSlotFavBar {
  kind: 'favBar';
}

interface ForestListSlotBarRoot {
  kind: 'barRoot';
  rootKey: string;
}

interface ForestSlotUnclassified {
  kind: 'unclassified';
}

type ForestListSlot = ForestSlotFavBar | ForestListSlotBarRoot | ForestSlotUnclassified;

function forestListSlotsFromForest(forest: BookmarkNavForest): Array<ForestListSlot> {
  const slots: Array<ForestListSlot> = [];
  if (forest.favBarGroup !== null) {
    const slotFav: ForestSlotFavBar = { kind: 'favBar' };
    slots.push(slotFav);
  }
  let ri: number = 0;
  while (ri < forest.barFolderRoots.length) {
    slots.push({ kind: 'barRoot', rootKey: forest.barFolderRoots[ri].folder });
    ri++;
  }
  if (forest.unclassifiedGroup !== null) {
    const slotUn: ForestSlotUnclassified = { kind: 'unclassified' };
    slots.push(slotUn);
  }
  return slots;
}

function rebuildBookmarkGroupsBySlotOrder(
  groups: Array<BookmarkGroup>,
  slots: Array<ForestListSlot>
): Array<BookmarkGroup> {
  let favBar: BookmarkGroup | null = null;
  let uncl: BookmarkGroup | null = null;
  let fi: number = 0;
  while (fi < groups.length) {
    if (groups[fi].folder === '收藏夹栏') {
      favBar = groups[fi];
    }
    if (groups[fi].folder === '未分类') {
      uncl = groups[fi];
    }
    fi++;
  }
  const out: Array<BookmarkGroup> = [];
  let si: number = 0;
  while (si < slots.length) {
    const s: ForestListSlot = slots[si];
    if (s.kind === 'favBar' && favBar !== null) {
      out.push(favBar);
    } else if (s.kind === 'unclassified' && uncl !== null) {
      out.push(uncl);
    } else if (s.kind === 'barRoot') {
      const rk: string = s.rootKey;
      let gj: number = 0;
      while (gj < groups.length) {
        if (bookmarkRootKeyForFolder(groups[gj].folder) === rk) {
          out.push(groups[gj]);
        }
        gj++;
      }
    }
    si++;
  }
  return out;
}

/**
 * 主列表与 buildBookmarkNavForest 一致时的根级拖拽：调整顶层块顺序并重排扁平 bookmarkGroups。
 */
export function reorderBookmarkGroupsByForestSlots(
  groups: Array<BookmarkGroup>,
  forest: BookmarkNavForest,
  from: number,
  to: number
): Array<BookmarkGroup> | null {
  const slots: Array<ForestListSlot> = forestListSlotsFromForest(forest);
  const moved: Array<ForestListSlot> | null = reorderArrayItems(slots, from, to);
  if (moved === null) {
    return null;
  }
  return rebuildBookmarkGroupsBySlotOrder(groups, moved);
}

// ── 通用数组工具 ─────────────────────────────────────────────────────────────

/**
 * 将数组中 `from` 位置的元素移动到 `to` 位置（返回新数组，原数组不变）。
 * 越界或 from===to 时返回 null（调用方跳过更新）。
 */
export function reorderArrayItems<T>(arr: Array<T>, from: number, to: number): Array<T> | null {
  if (from === to || from < 0 || to < 0 || from >= arr.length || to >= arr.length) {
    return null;
  }
  const copy: Array<T> = [];
  let i: number = 0;
  while (i < arr.length) {
    copy.push(arr[i]);
    i++;
  }
  const moved: T = copy.splice(from, 1)[0];
  copy.splice(to, 0, moved);
  return copy;
}

/**
 * 从书签列表中删除匹配 folder+url 的单条书签（返回新数组）。
 */
export function removeBookmarkByKey(
  items: Array<BookmarkItem>,
  folder: string,
  url: string
): Array<BookmarkItem> {
  const folderNorm: string = normalizeBookmarkFolderPath(folder);
  const next: Array<BookmarkItem> = [];
  let i: number = 0;
  while (i < items.length) {
    const itemFolderNorm: string = normalizeBookmarkFolderPath(items[i].folder);
    if (!(itemFolderNorm === folderNorm && items[i].url === url)) {
      next.push(items[i]);
    }
    i++;
  }
  return next;
}

/**
 * 判断文件夹是否在展开列表中。
 */
export function isFolderInExpandedList(expandedFolders: Array<string>, folder: string): boolean {
  return expandedFolders.indexOf(folder) >= 0;
}

/**
 * 父路径（用于「同级仅展开一个」）。单段路径（如「未分类」）返回 ''。
 */
export function parentFolderPathForExpand(folder: string): string {
  const segs: Array<string> = splitBookmarkFolderSegments(folder);
  if (segs.length <= 1) {
    return '';
  }
  return segs.slice(0, segs.length - 1).join(' / ');
}

/**
 * 树形列表展示所需：从根段到完整路径的每一级（如 收藏夹栏 → 收藏夹栏 / 杂项 → …），
 * 用于新建/移动后自动展开整条祖先链，否则仅展开叶子路径时父级折叠、子文件夹不可见。
 */
export function folderPathAncestorChainForExpand(folder: string): Array<string> {
  const segs: Array<string> = splitBookmarkFolderSegments(folder);
  if (segs.length === 0) {
    return [];
  }
  const out: Array<string> = [];
  let acc: string = segs[0];
  out.push(acc);
  let i: number = 1;
  while (i < segs.length) {
    acc = `${acc} / ${segs[i]}`;
    out.push(acc);
    i++;
  }
  return out;
}

/**
 * 同级（同一父路径下）仅允许一个文件夹处于展开状态；父文件夹与子文件夹可同时展开。
 * 收起某文件夹时，同时移除其下所有子路径的展开状态。
 */
export function toggleFolderExpandSiblingExclusive(
  expanded: Array<string>,
  folder: string
): Array<string> {
  const idx: number = expanded.indexOf(folder);
  if (idx >= 0) {
    const next: Array<string> = [];
    const prefix: string = folder + ' / ';
    let i: number = 0;
    while (i < expanded.length) {
      const f: string = expanded[i];
      if (f !== folder && !f.startsWith(prefix)) {
        next.push(f);
      }
      i++;
    }
    return next;
  }
  const parent: string = parentFolderPathForExpand(folder);
  const nextOpen: Array<string> = [];
  let j: number = 0;
  while (j < expanded.length) {
    const f: string = expanded[j];
    const isSibling: boolean = parentFolderPathForExpand(f) === parent && f !== folder;
    if (!isSibling) {
      nextOpen.push(f);
    }
    j++;
  }
  nextOpen.push(folder);
  return nextOpen;
}

/**
 * 同一父路径下的直接子文件夹分组在 bookmarkGroups 中的顺序拖拽（与导航树子节点顺序一致）。
 */
export function reorderSiblingGroupsInBookmarkGroups(
  groups: Array<BookmarkGroup>,
  parentPath: string,
  from: number,
  to: number
): Array<BookmarkGroup> | null {
  const sibIdx: Array<number> = [];
  let i: number = 0;
  while (i < groups.length) {
    if (parentFolderPathForExpand(groups[i].folder) === parentPath) {
      sibIdx.push(i);
    }
    i++;
  }
  if (sibIdx.length === 0) {
    return null;
  }
  const siblingGroups: Array<BookmarkGroup> = [];
  let si: number = 0;
  while (si < sibIdx.length) {
    siblingGroups.push(groups[sibIdx[si]]);
    si++;
  }
  const moved: Array<BookmarkGroup> | null = reorderArrayItems(siblingGroups, from, to);
  if (moved === null) {
    return null;
  }
  const out: Array<BookmarkGroup> = [];
  let inserted: boolean = false;
  let gi: number = 0;
  while (gi < groups.length) {
    let isSib: boolean = false;
    let sk: number = 0;
    while (sk < sibIdx.length) {
      if (sibIdx[sk] === gi) {
        isSib = true;
        break;
      }
      sk++;
    }
    if (isSib) {
      if (!inserted) {
        let mi: number = 0;
        while (mi < moved.length) {
          out.push(moved[mi]);
          mi++;
        }
        inserted = true;
      }
      gi++;
    } else {
      out.push(groups[gi]);
      gi++;
    }
  }
  return out;
}

/**
 * 切换文件夹展开/折叠（返回新数组，原数组不变）。
 */
export function toggleFolderInExpandedList(
  expandedFolders: Array<string>,
  folder: string
): Array<string> {
  const idx: number = expandedFolders.indexOf(folder);
  if (idx >= 0) {
    const next: Array<string> = [];
    let i: number = 0;
    while (i < expandedFolders.length) {
      if (i !== idx) {
        next.push(expandedFolders[i]);
      }
      i++;
    }
    return next;
  }
  const merged: Array<string> = [];
  let j: number = 0;
  while (j < expandedFolders.length) {
    merged.push(expandedFolders[j]);
    j++;
  }
  merged.push(folder);
  return merged;
}

/**
 * 根据背景亮度偏移计算遮罩颜色（delta>0 加白膜，delta<0 加黑膜）。
 */
export function backgroundMaskColorFromBrightness(brightnessLevel: number): string {
  const delta: number = brightnessLevel - 50;
  if (delta === 0) {
    return '#00000000';
  }
  const alphaRatio: number = Math.abs(delta) / 50 * 0.35;
  const alpha: number = Math.floor(alphaRatio * 255);
  const alphaHex: string = alpha.toString(16).padStart(2, '0').toUpperCase();
  return delta > 0 ? `#${alphaHex}FFFFFF` : `#${alphaHex}000000`;
}
