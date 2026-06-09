import http from '@ohos.net.http';

const GITEE_API_PREFIX: string = 'https://gitee.com/api/v5';

interface GiteeGistPatchFileEntry {
  content: string;
}

interface GiteeGistPatchRequestBody {
  description: string;
  files: Record<string, GiteeGistPatchFileEntry>;
}

interface GiteeGistCreateRequestBody {
  access_token: string;
  description: string;
  public: boolean;
  files: Record<string, GiteeGistPatchFileEntry>;
}

export interface GiteeEnsureGistResult {
  gistId: string;
  created: boolean;
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
      readTimeout: 60000,
      usingProtocol: http.HttpProtocol.HTTP1_1
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

/** GET 当前授权用户的代码片段列表，用于自动配置时复用已有同步片段。 */
export async function giteeListGistsRaw(token: string): Promise<string> {
  const url: string = giteeUrlWithToken('/gists?per_page=100', token);
  return httpGiteeString(http.RequestMethod.GET, url, giteeJsonHeaders(), undefined);
}

function findGiteeGistIdByFileName(gistsJson: string, fileName: string): string {
  const arr: Array<Object> = JSON.parse(gistsJson) as Array<Object>;
  let i: number = 0;
  while (i < arr.length) {
    const item = arr[i] as Record<string, Object | undefined>;
    const idVal: Object | undefined = item['id'];
    if (typeof idVal !== 'string' || (idVal as string).length === 0) {
      i++;
      continue;
    }

    const filesVal: Object | undefined = item['files'];
    if (filesVal !== undefined) {
      if (typeof filesVal === 'string' && (filesVal as string).indexOf(fileName) >= 0) {
        return idVal as string;
      }
      const filesRec = filesVal as Record<string, Object | undefined>;
      if (filesRec[fileName] !== undefined) {
        return idVal as string;
      }
    }

    const descVal: Object | undefined = item['description'];
    if (typeof descVal === 'string' && (descVal as string) === fileName) {
      return idVal as string;
    }
    i++;
  }
  return '';
}

function parseCreatedGiteeGistId(raw: string): string {
  const parsed: Object = JSON.parse(raw) as Object;
  let rec: Record<string, Object | undefined> | null = null;
  if (Array.isArray(parsed)) {
    const arr = parsed as Array<Object>;
    if (arr.length > 0) {
      rec = arr[0] as Record<string, Object | undefined>;
    }
  } else {
    rec = parsed as Record<string, Object | undefined>;
  }
  if (rec !== null) {
    const idVal: Object | undefined = rec['id'];
    if (typeof idVal === 'string' && (idVal as string).length > 0) {
      return idVal as string;
    }
  }
  return '';
}

/** 创建私密 Gitee 代码片段，返回新片段 ID。 */
export async function giteeCreateGistWithFile(
  token: string,
  fileName: string,
  fileContent: string
): Promise<string> {
  const url: string = giteeUrlWithToken('/gists', token);
  const fileEntry: GiteeGistPatchFileEntry = { content: fileContent };
  const filesMap: Record<string, GiteeGistPatchFileEntry> = {};
  filesMap[fileName] = fileEntry;
  const payload: GiteeGistCreateRequestBody = {
    access_token: token,
    description: fileName,
    public: false,
    files: filesMap
  };
  const raw: string = await httpGiteeString(http.RequestMethod.POST, url, giteeJsonHeaders(), JSON.stringify(payload));
  const id: string = parseCreatedGiteeGistId(raw);
  if (id.length === 0) {
    throw new Error('Gitee 已创建代码片段，但响应中没有 id');
  }
  return id;
}

/** 自动配置用：优先复用含指定文件名的片段，没有则创建私密代码片段。 */
export async function giteeEnsureGistWithFile(
  token: string,
  fileName: string,
  initialContent: string
): Promise<GiteeEnsureGistResult> {
  const listJson: string = await giteeListGistsRaw(token);
  const existingId: string = findGiteeGistIdByFileName(listJson, fileName);
  if (existingId.length > 0) {
    return { gistId: existingId, created: false };
  }
  const newId: string = await giteeCreateGistWithFile(token, fileName, initialContent);
  return { gistId: newId, created: true };
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
