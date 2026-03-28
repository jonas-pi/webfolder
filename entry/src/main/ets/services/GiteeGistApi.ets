import http from '@ohos.net.http';

const GITEE_API_PREFIX: string = 'https://gitee.com/api/v5';

interface GiteeGistPatchFileEntry {
  content: string;
}

interface GiteeGistPatchRequestBody {
  description: string;
  files: Record<string, GiteeGistPatchFileEntry>;
}

function giteeUrlWithToken(path: string, token: string): string {
  const q: string = path.includes('?') ? '&' : '?';
  return `${GITEE_API_PREFIX}${path}${q}access_token=${encodeURIComponent(token)}`;
}

function giteeJsonHeaders(): Record<string, string> {
  return {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    'User-Agent': 'HarmonyOS-HM-Bookmarks/1.0',
    'Cache-Control': 'no-store'
  };
}

function parseGiteeErrorMessage(statusBody: string): string {
  if (statusBody.length === 0) {
    return `HTTP 错误`;
  }
  try {
    const obj: object = JSON.parse(statusBody) as object;
    const rec = obj as Record<string, string | undefined>;
    const msg: string | undefined = rec['message'];
    if (msg !== undefined && msg.length > 0) {
      return msg;
    }
  } catch (_e) {
  }
  const maxLen: number = 240;
  return statusBody.length > maxLen ? statusBody.substring(0, maxLen) + '…' : statusBody;
}

async function httpGiteeString(
  method: http.RequestMethod | string,
  fullUrl: string,
  headers: Record<string, string>,
  body: string | undefined
): Promise<string> {
  const request: http.HttpRequest = http.createHttp();
  try {
    const opt: http.HttpRequestOptions = {
      method: method as http.RequestMethod,
      header: headers,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 60000,
      readTimeout: 60000
    };
    if (body !== undefined && body.length > 0) {
      opt.extraData = body;
    }
    const response: http.HttpResponse = await request.request(fullUrl, opt);
    const raw: string = typeof response.result === 'string' ? (response.result as string) : '';
    if (response.responseCode < 200 || response.responseCode >= 300) {
      throw new Error(parseGiteeErrorMessage(raw));
    }
    return raw;
  } finally {
    request.destroy();
  }
}

/** GET /gists/{id}，Token 走 query `access_token`。 */
export async function giteeFetchGistRaw(token: string, gistId: string): Promise<string> {
  const url: string = giteeUrlWithToken(`/gists/${gistId}`, token);
  return httpGiteeString(http.RequestMethod.GET, url, giteeJsonHeaders(), undefined);
}

function rawUrlWithToken(rawUrl: string, token: string): string {
  const q: string = rawUrl.includes('?') ? '&' : '?';
  return `${rawUrl}${q}access_token=${encodeURIComponent(token)}`;
}

/**
 * 从 Gitee 片段 JSON 中取指定文件内容；结构与 GitHub Gist 相近（files / content / truncated / raw_url）。
 */
export async function giteeExtractGistFileText(
  token: string,
  gistJson: string,
  fileName: string
): Promise<string> {
  const root: object = JSON.parse(gistJson) as object;
  const rec = root as Record<string, Object | undefined>;
  const filesVal: Object | undefined = rec['files'];
  if (filesVal === undefined) {
    throw new Error('代码片段响应中无 files 字段');
  }
  const filesRec = filesVal as Record<string, Object | undefined>;
  const fileEntry: Object | undefined = filesRec[fileName];
  if (fileEntry === undefined) {
    throw new Error(`片段中不存在文件「${fileName}」，请检查文件名`);
  }
  const fileRec = fileEntry as Record<string, Object | undefined>;
  const truncatedVal: Object | undefined = fileRec['truncated'];
  const isTruncated: boolean = truncatedVal === true;
  if (!isTruncated) {
    const contentVal: Object | undefined = fileRec['content'];
    if (typeof contentVal === 'string') {
      return contentVal as string;
    }
    throw new Error('无法读取片段文件 content');
  }
  const rawUrlVal: Object | undefined = fileRec['raw_url'];
  if (typeof rawUrlVal !== 'string' || (rawUrlVal as string).length === 0) {
    throw new Error('大文件已截断但缺少 raw_url');
  }
  const rawUrl: string = rawUrlVal as string;
  const urlWithTok: string = rawUrlWithToken(rawUrl, token);
  return httpGiteeString(http.RequestMethod.GET, urlWithTok, giteeJsonHeaders(), undefined);
}

/** PATCH /gists/{id}，与 BookmarkHub 写入结构一致（单文件 content）。 */
export async function giteePatchGistFiles(
  token: string,
  gistId: string,
  fileName: string,
  fileContent: string
): Promise<void> {
  const url: string = giteeUrlWithToken(`/gists/${gistId}`, token);
  const fileEntry: GiteeGistPatchFileEntry = { content: fileContent };
  const filesMap: Record<string, GiteeGistPatchFileEntry> = {};
  filesMap[fileName] = fileEntry;
  const payload: GiteeGistPatchRequestBody = {
    description: fileName,
    files: filesMap
  };
  const body: string = JSON.stringify(payload);
  await httpGiteeString('PATCH', url, giteeJsonHeaders(), body);
}
