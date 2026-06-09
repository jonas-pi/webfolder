import http from '@ohos.net.http';

/**
 * GitHub OAuth App Client ID.
 *
 * 需要在 GitHub OAuth App 设置中启用 Device Flow，然后把 Client ID 填到这里。
 * Device Flow 不需要把 client_secret 放进客户端。
 */
export const GITHUB_OAUTH_CLIENT_ID: string = 'Ov23liYOhQmlDDlZBCgB';

const GITHUB_OAUTH_SCOPE: string = 'gist';
const GITHUB_DEVICE_CODE_URL: string = 'https://github.com/login/device/code';
const GITHUB_ACCESS_TOKEN_URL: string = 'https://github.com/login/oauth/access_token';
const GITHUB_DEVICE_GRANT_TYPE: string = 'urn:ietf:params:oauth:grant-type:device_code';

export interface GithubDeviceCodeResult {
  deviceCode: string;
  userCode: string;
  verificationUri: string;
  expiresIn: number;
  interval: number;
}

export interface GithubOAuthTokenResult {
  accessToken: string;
  scope: string;
  tokenType: string;
}

interface GithubOAuthHttpResult {
  responseCode: number;
  raw: string;
}

export function isGithubOAuthConfigured(): boolean {
  return GITHUB_OAUTH_CLIENT_ID.trim().length > 0;
}

function oauthHeaders(): Record<string, string> {
  return {
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
    'User-Agent': 'HarmonyOS-HM-Bookmarks/1.0',
    'Cache-Control': 'no-store'
  };
}

function formPair(key: string, value: string): string {
  return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
}

function formBody(params: Record<string, string>): string {
  const parts: Array<string> = [];
  Object.keys(params).forEach((k: string): void => {
    parts.push(formPair(k, params[k]));
  });
  return parts.join('&');
}

function stringField(rec: Record<string, Object | undefined>, key: string): string {
  const val: Object | undefined = rec[key];
  return typeof val === 'string' ? (val as string) : '';
}

function numberField(rec: Record<string, Object | undefined>, key: string, fallback: number): number {
  const val: Object | undefined = rec[key];
  return typeof val === 'number' ? (val as number) : fallback;
}

function parseGithubOAuthError(raw: string): string {
  if (raw.length === 0) {
    return 'GitHub OAuth 请求失败';
  }
  try {
    const rec = JSON.parse(raw) as Record<string, Object | undefined>;
    const err: string = stringField(rec, 'error');
    const desc: string = stringField(rec, 'error_description');
    if (err.length > 0 && desc.length > 0) {
      return `${err}: ${desc}`;
    }
    if (err.length > 0) {
      return err;
    }
  } catch (_e) {
  }
  const maxLen: number = 240;
  return raw.length > maxLen ? raw.substring(0, maxLen) + '…' : raw;
}

async function httpGithubOAuthText(fullUrl: string, body: string): Promise<GithubOAuthHttpResult> {
  const request: http.HttpRequest = http.createHttp();
  try {
    const opt: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: oauthHeaders(),
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 60000,
      readTimeout: 60000,
      usingProtocol: http.HttpProtocol.HTTP1_1,
      extraData: body
    };
    const response: http.HttpResponse = await request.request(fullUrl, opt);
    const raw: string = typeof response.result === 'string' ? (response.result as string) : '';
    return {
      responseCode: response.responseCode,
      raw: raw
    };
  } finally {
    request.destroy();
  }
}

async function httpGithubOAuthJson(fullUrl: string, body: string): Promise<string> {
  const result: GithubOAuthHttpResult = await httpGithubOAuthText(fullUrl, body);
  if (result.responseCode < 200 || result.responseCode >= 300) {
    throw new Error(parseGithubOAuthError(result.raw));
  }
  return result.raw;
}

async function httpGithubOAuthPollJson(fullUrl: string, body: string): Promise<string> {
  const result: GithubOAuthHttpResult = await httpGithubOAuthText(fullUrl, body);
  if (result.raw.length === 0 && (result.responseCode < 200 || result.responseCode >= 300)) {
    throw new Error(`GitHub OAuth 请求失败: HTTP ${result.responseCode}`);
  }
  return result.raw;
}

function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve) => {
    setTimeout((): void => {
      resolve();
    }, ms);
  });
}

export async function requestGithubDeviceCode(): Promise<GithubDeviceCodeResult> {
  const clientId: string = GITHUB_OAUTH_CLIENT_ID.trim();
  if (clientId.length === 0) {
    throw new Error('未配置 GitHub OAuth Client ID');
  }
  const params: Record<string, string> = {};
  params['client_id'] = clientId;
  params['scope'] = GITHUB_OAUTH_SCOPE;
  const raw: string = await httpGithubOAuthJson(GITHUB_DEVICE_CODE_URL, formBody(params));
  const rec = JSON.parse(raw) as Record<string, Object | undefined>;
  const deviceCode: string = stringField(rec, 'device_code');
  const userCode: string = stringField(rec, 'user_code');
  const verificationUri: string = stringField(rec, 'verification_uri');
  if (deviceCode.length === 0 || userCode.length === 0 || verificationUri.length === 0) {
    throw new Error('GitHub 没有返回完整的设备授权码');
  }
  return {
    deviceCode: deviceCode,
    userCode: userCode,
    verificationUri: verificationUri,
    expiresIn: numberField(rec, 'expires_in', 900),
    interval: numberField(rec, 'interval', 5)
  };
}

export async function pollGithubDeviceAccessToken(
  deviceCode: string,
  intervalSeconds: number,
  expiresInSeconds: number
): Promise<GithubOAuthTokenResult> {
  const clientId: string = GITHUB_OAUTH_CLIENT_ID.trim();
  if (clientId.length === 0) {
    throw new Error('未配置 GitHub OAuth Client ID');
  }
  let waitSeconds: number = intervalSeconds > 0 ? intervalSeconds : 5;
  const expiresAt: number = Date.now() + (expiresInSeconds > 0 ? expiresInSeconds : 900) * 1000;
  while (Date.now() < expiresAt) {
    await sleep(waitSeconds * 1000);
    const params: Record<string, string> = {};
    params['client_id'] = clientId;
    params['device_code'] = deviceCode;
    params['grant_type'] = GITHUB_DEVICE_GRANT_TYPE;
    const raw: string = await httpGithubOAuthPollJson(GITHUB_ACCESS_TOKEN_URL, formBody(params));
    const rec = JSON.parse(raw) as Record<string, Object | undefined>;
    const token: string = stringField(rec, 'access_token');
    if (token.length > 0) {
      const scope: string = stringField(rec, 'scope');
      if (scope.indexOf('gist') < 0) {
        throw new Error('GitHub 授权未包含 gist 权限');
      }
      return {
        accessToken: token,
        scope: scope,
        tokenType: stringField(rec, 'token_type')
      };
    }
    const err: string = stringField(rec, 'error');
    if (err === 'authorization_pending') {
      continue;
    }
    if (err === 'slow_down') {
      const nextInterval: number = numberField(rec, 'interval', 0);
      waitSeconds = nextInterval > waitSeconds ? nextInterval : waitSeconds + 5;
      continue;
    }
    if (err === 'expired_token' || err === 'token_expired') {
      throw new Error('GitHub 授权码已过期，请重新连接');
    }
    if (err === 'access_denied') {
      throw new Error('GitHub 授权已取消');
    }
    if (err.length > 0) {
      const desc: string = stringField(rec, 'error_description');
      throw new Error(desc.length > 0 ? `${err}: ${desc}` : err);
    }
    throw new Error('GitHub OAuth 响应中没有 access_token');
  }
  throw new Error('GitHub 授权等待超时，请重新连接');
}
