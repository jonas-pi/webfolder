import { Want } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { systemShare } from '@kit.ShareKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'WBShare';

/** 与 Index 中订阅的 eventId 一致（emitter 使用 string eventId） */
export const WB_SHARE_INCOMING_EVENT_ID: string = 'webbookmarks_share_incoming';

/** 深浅色/窗口形态等变化后，页面需按当前「沉浸顶栏」选项重设系统栏 */
export const WB_CONFIGURATION_CHANGED_EVENT_ID: string = 'webbookmarks_configuration_changed';

export interface ShareLinkPayload {
  url: string;
  title: string;
}

let pendingUrl: string = '';
let pendingTitle: string = '';

export function peekPendingShare(): ShareLinkPayload | null {
  if (pendingUrl.length === 0) {
    return null;
  }
  return { url: pendingUrl, title: pendingTitle };
}

export function clearPendingShare(): void {
  pendingUrl = '';
  pendingTitle = '';
}

function setPendingShare(url: string, title: string): void {
  pendingUrl = url.trim();
  pendingTitle = title.trim();
}

function emitShareIncoming(): void {
  emitter.emit(
    WB_SHARE_INCOMING_EVENT_ID,
    { priority: emitter.EventPriority.HIGH },
    { data: { t: Date.now() } }
  );
}

export function isSendDataWant(want: Want): boolean {
  return want.action === 'ohos.want.action.sendData';
}

function firstHttpUrlInText(text: string): string {
  const t: string = text.trim();
  if (t.length === 0) {
    return '';
  }
  if (t.startsWith('http://') || t.startsWith('https://')) {
    return t.split(/\s/)[0].trim();
  }
  const m: RegExpMatchArray | null = t.match(/https?:\/\/[^\s<>"']+/);
  return m !== null ? m[0].trim() : '';
}

function stringField(obj: object, key: string): string {
  const o: Record<string, Object> = obj as Record<string, Object>;
  const raw: Object | undefined = o[key];
  return typeof raw === 'string' ? raw : '';
}

/**
 * 从 Share Kit 记录中尽量解析出 HTTP(S) 链接与可选标题（不同宿主字段略有差异）。
 */
export function parseShareLinkFromRecords(records: Array<systemShare.SharedRecord>): ShareLinkPayload | null {
  let bestUrl: string = '';
  let bestTitle: string = '';
  let i: number = 0;
  while (i < records.length) {
    const rec: systemShare.SharedRecord = records[i];
    const loose: object = rec as object;
    const content: string = stringField(loose, 'content');
    const uri: string = stringField(loose, 'uri');
    const title: string = stringField(loose, 'title');
    const abstract: string = stringField(loose, 'abstract');

    let url: string = '';
    if (uri.length > 0 && (uri.startsWith('http://') || uri.startsWith('https://'))) {
      url = uri.trim();
    } else if (content.length > 0) {
      url = firstHttpUrlInText(content);
    }
    if (url.length > 0) {
      bestUrl = url;
      bestTitle = title.length > 0 ? title : (abstract.length > 0 ? abstract : '');
      break;
    }
    i++;
  }
  if (bestUrl.length === 0) {
    return null;
  }
  return { url: bestUrl, title: bestTitle };
}

/**
 * 异步拉取 Want 中的分享数据；成功且解析出链接后写入 pending 并发出事件。
 */
export function consumeShareWant(want: Want): void {
  if (!isSendDataWant(want)) {
    return;
  }
  systemShare.getSharedData(want)
    .then((data: systemShare.SharedData) => {
      const parsed: ShareLinkPayload | null = parseShareLinkFromRecords(data.getRecords());
      if (parsed === null || parsed.url.length === 0) {
        return;
      }
      setPendingShare(parsed.url, parsed.title);
      emitShareIncoming();
    })
    .catch((err: Object) => {
      hilog.warn(DOMAIN, TAG, 'getSharedData: %{public}s', JSON.stringify(err));
    });
}
