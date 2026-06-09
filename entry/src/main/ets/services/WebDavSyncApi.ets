import http from '@ohos.net.http';

function normalizeWebDavFileUrl(rawUrl: string): string {
  const url: string = rawUrl.trim();
  if (url.length === 0) {
    throw new Error('请填写 WebDAV 文件地址');
  }
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    throw new Error('WebDAV 地址需以 http:// 或 https:// 开头');
  }
  return url;
}

function hexValue(ch: string): number {
  const code: number = ch.charCodeAt(0);
  if (code >= 48 && code <= 57) {
    return code - 48;
  }
  if (code >= 65 && code <= 70) {
    return code - 55;
  }
  if (code >= 97 && code <= 102) {
    return code - 87;
  }
  return 0;
}

function stringToUtf8Bytes(input: string): number[] {
  const bytes: number[] = [];
  let encoded: string = '';
  try {
    encoded = encodeURIComponent(input);
  } catch (_e) {
    encoded = input;
  }
  let i: number = 0;
  while (i < encoded.length) {
    const ch: string = encoded.charAt(i);
    if (ch === '%' && i + 2 < encoded.length) {
      const byteVal: number = hexValue(encoded.charAt(i + 1)) * 16 + hexValue(encoded.charAt(i + 2));
      bytes.push(byteVal);
      i = i + 3;
    } else {
      bytes.push(encoded.charCodeAt(i) & 0xff);
      i = i + 1;
    }
  }
  return bytes;
}

function base64EncodeBytes(bytes: number[]): string {
  const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  let output: string = '';
  let i: number = 0;
  while (i < bytes.length) {
    const byte1: number = bytes[i++] & 0xff;
    const hasByte2: boolean = i < bytes.length;
    const byte2: number = hasByte2 ? bytes[i++] & 0xff : 0;
    const hasByte3: boolean = i < bytes.length;
    const byte3: number = hasByte3 ? bytes[i++] & 0xff : 0;
    output += chars.charAt(byte1 >> 2);
    output += chars.charAt(((byte1 & 0x03) << 4) | (byte2 >> 4));
    output += hasByte2 ? chars.charAt(((byte2 & 0x0f) << 2) | (byte3 >> 6)) : '=';
    output += hasByte3 ? chars.charAt(byte3 & 0x3f) : '=';
  }
  return output;
}

function webDavHeaders(username: string, password: string, hasBody: boolean): Record<string, string> {
  const headers: Record<string, string> = {
    'Accept': 'application/json, text/plain, */*',
    'User-Agent': 'HarmonyOS-HM-Bookmarks/1.0',
    'Cache-Control': 'no-store'
  };
  if (hasBody) {
    headers['Content-Type'] = 'application/json; charset=utf-8';
  }
  if (username.trim().length > 0 || password.length > 0) {
    const token: string = base64EncodeBytes(stringToUtf8Bytes(`${username}:${password}`));
    headers['Authorization'] = `Basic ${token}`;
  }
  return headers;
}

function parseWebDavErrorMessage(statusCode: number, statusBody: string): string {
  const prefix: string = `WebDAV HTTP ${statusCode}`;
  if (statusBody.length === 0) {
    return prefix;
  }
  const maxLen: number = 240;
  const body: string = statusBody.length > maxLen ? statusBody.substring(0, maxLen) + '…' : statusBody;
  return `${prefix}: ${body}`;
}

async function httpWebDavString(
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
    if (body !== undefined) {
      opt.extraData = body;
    }
    const response: http.HttpResponse = await request.request(fullUrl, opt);
    const raw: string = typeof response.result === 'string' ? (response.result as string) : '';
    if (response.responseCode < 200 || response.responseCode >= 300) {
      throw new Error(parseWebDavErrorMessage(response.responseCode, raw));
    }
    return raw;
  } finally {
    request.destroy();
  }
}

export async function webDavFetchFileText(
  webDavUrl: string,
  username: string,
  password: string
): Promise<string> {
  const url: string = normalizeWebDavFileUrl(webDavUrl);
  return httpWebDavString(http.RequestMethod.GET, url, webDavHeaders(username.trim(), password, false), undefined);
}

export async function webDavPutFileText(
  webDavUrl: string,
  username: string,
  password: string,
  fileContent: string
): Promise<void> {
  const url: string = normalizeWebDavFileUrl(webDavUrl);
  await httpWebDavString('PUT', url, webDavHeaders(username.trim(), password, true), fileContent);
}
