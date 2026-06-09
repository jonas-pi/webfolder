import http from '@ohos.net.http';

const GITHUB_API_PREFIX: string = 'https://api.github.com';

/**
 * GitHub PATCH /gists/{id} 时 `files` 下单个文件的字段（arkts-no-untyped-obj-literals 要求显式类型）。
 */
interface GithubGistPatchFileEntry {
  content: string;
}

/** PATCH 请求体顶层：与 BookmarkHub `files: { [name]: { content } }` 一致 */
interface GithubGistPatchRequestBody {
  description: string;
  files: Record<string, GithubGistPatchFileEntry>;
}

/** 创建 Secret Gist 的请求体 */
interface GithubCreateGistRequestBody {
  description: string;
  public: boolean;
  files: Record<string, GithubGistPatchFileEntry>;
}

export interface GithubEnsureGistResult {
  gistId: string;
  created: boolean;
}

/**
 * 构造 GitHub REST 请求头（与 BookmarkHub 扩展使用的 API 版本一致）。
 */
function githubJsonHeaders(token: string): Record<string, string> {
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'HarmonyOS-HM-Bookmarks/1.0',
    'Cache-Control': 'no-store'
  };
}

function githubRawHeaders(token: string): Record<string, string> {
  return {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/vnd.github.v3.raw',
    'User-Agent': 'HarmonyOS-HM-Bookmarks/1.0'
  };
}

/**
 * 从错误响应体中尽量解析 `message` 字段，便于 Toast 展示。
 */
function parseGithubErrorMessage(statusBody: string): string {
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
    // 非 JSON 时退回截断原文
  }
  const maxLen: number = 240;
  return statusBody.length > maxLen ? statusBody.substring(0, maxLen) + '…' : statusBody;
}

async function httpGithubString(
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
      throw new Error(parseGithubErrorMessage(raw));
    }
    return raw;
  } finally {
    request.destroy();
  }
}

/**
 * GET `gists/{id}` 的原始 JSON 字符串。
 */
export async function githubFetchGistRaw(token: string, gistId: string): Promise<string> {
  const url: string = `${GITHUB_API_PREFIX}/gists/${gistId}`;
  return httpGithubString(http.RequestMethod.GET, url, githubJsonHeaders(token), undefined);
}

/** GET 当前授权用户可访问的 Gist 列表，供自动配置时复用已有同步 Gist。 */
export async function githubListGistsRaw(token: string): Promise<string> {
  const url: string = `${GITHUB_API_PREFIX}/gists?per_page=100`;
  return httpGithubString(http.RequestMethod.GET, url, githubJsonHeaders(token), undefined);
}

function findGistIdByFileName(gistsJson: string, fileName: string): string {
  const arr: Array<Object> = JSON.parse(gistsJson) as Array<Object>;
  let i: number = 0;
  while (i < arr.length) {
    const item = arr[i] as Record<string, Object | undefined>;
    const filesVal: Object | undefined = item['files'];
    const idVal: Object | undefined = item['id'];
    if (filesVal !== undefined && typeof idVal === 'string') {
      const filesRec = filesVal as Record<string, Object | undefined>;
      if (filesRec[fileName] !== undefined) {
        return idVal as string;
      }
    }
    i++;
  }
  return '';
}

/** 创建私密 Gist，返回新建 Gist ID。 */
export async function githubCreateGistWithFile(
  token: string,
  fileName: string,
  fileContent: string
): Promise<string> {
  const url: string = `${GITHUB_API_PREFIX}/gists`;
  const fileEntry: GithubGistPatchFileEntry = { content: fileContent };
  const filesMap: Record<string, GithubGistPatchFileEntry> = {};
  filesMap[fileName] = fileEntry;
  const payload: GithubCreateGistRequestBody = {
    description: 'BookmarkHub sync data',
    public: false,
    files: filesMap
  };
  const raw: string = await httpGithubString(http.RequestMethod.POST, url, githubJsonHeaders(token), JSON.stringify(payload));
  const rec = JSON.parse(raw) as Record<string, Object | undefined>;
  const idVal: Object | undefined = rec['id'];
  if (typeof idVal !== 'string' || (idVal as string).length === 0) {
    throw new Error('GitHub 已创建 Gist，但响应中没有 id');
  }
  return idVal as string;
}

/**
 * 自动配置用：优先复用含指定文件名的 Gist；没有则创建一个 Secret Gist。
 */
export async function githubEnsureGistWithFile(
  token: string,
  fileName: string,
  initialContent: string
): Promise<GithubEnsureGistResult> {
  const listJson: string = await githubListGistsRaw(token);
  const existingId: string = findGistIdByFileName(listJson, fileName);
  if (existingId.length > 0) {
    return { gistId: existingId, created: false };
  }
  const newId: string = await githubCreateGistWithFile(token, fileName, initialContent);
  return { gistId: newId, created: true };
}

/**
 * 从 Gist JSON 中取指定文件的文本内容；若 `truncated` 为 true 则再请求 `raw_url`。
 */
export async function extractGistFileText(
  token: string,
  gistJson: string,
  fileName: string
): Promise<string> {
  const root: object = JSON.parse(gistJson) as object;
  const rec = root as Record<string, Object | undefined>;
  const filesVal: Object | undefined = rec['files'];
  if (filesVal === undefined) {
    throw new Error('Gist 响应中无 files 字段');
  }
  const filesRec = filesVal as Record<string, Object | undefined>;
  const fileEntry: Object | undefined = filesRec[fileName];
  if (fileEntry === undefined) {
    throw new Error(`Gist 中不存在文件「${fileName}」，请检查文件名是否与扩展一致`);
  }
  const fileRec = fileEntry as Record<string, Object | undefined>;
  const truncatedVal: Object | undefined = fileRec['truncated'];
  const isTruncated: boolean = truncatedVal === true;
  if (!isTruncated) {
    const contentVal: Object | undefined = fileRec['content'];
    if (typeof contentVal === 'string') {
      return contentVal as string;
    }
    throw new Error('无法读取 Gist 文件 content');
  }
  const rawUrlVal: Object | undefined = fileRec['raw_url'];
  if (typeof rawUrlVal !== 'string' || (rawUrlVal as string).length === 0) {
    throw new Error('大文件已截断但缺少 raw_url');
  }
  const rawUrl: string = rawUrlVal as string;
  return httpGithubString(http.RequestMethod.GET, rawUrl, githubRawHeaders(token), undefined);
}

/**
 * PATCH 更新 Gist 中单个文件（与 BookmarkHub `BookmarkService.update` 一致）。
 */
export async function githubPatchGistFiles(
  token: string,
  gistId: string,
  fileName: string,
  fileContent: string
): Promise<void> {
  const url: string = `${GITHUB_API_PREFIX}/gists/${gistId}`;
  const fileEntry: GithubGistPatchFileEntry = { content: fileContent };
  const filesMap: Record<string, GithubGistPatchFileEntry> = {};
  filesMap[fileName] = fileEntry;
  const payload: GithubGistPatchRequestBody = {
    description: fileName,
    files: filesMap
  };
  const body: string = JSON.stringify(payload);
  await httpGithubString('PATCH', url, githubJsonHeaders(token), body);
}
