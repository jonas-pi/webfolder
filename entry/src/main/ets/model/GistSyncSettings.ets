/** 与 GitHub Gist / BookmarkHub 扩展一致 */
export const GIST_PROVIDER_GITHUB: string = 'github';
/** Gitee 代码片段（OpenAPI v5，国内访问更稳定） */
export const GIST_PROVIDER_GITEE: string = 'gitee';
/** WebDAV 文件同步（直接读写 BookmarkHub JSON 文件） */
export const GIST_PROVIDER_WEBDAV: string = 'webdav';

/** 默认片段内文件名（与扩展默认一致） */
export const DEFAULT_GIST_FILE_NAME: string = 'BookmarkHub';

/**
 * 单一片段云端（GitHub 或 Gitee）下的令牌与片段定位；两套配置独立持久化。
 */
export interface GistProviderCredentials {
  gistToken: string;
  gistId: string;
  gistFileName: string;
}

/**
 * WebDAV 文件定位；URL 指向实际 JSON 文件，而不是目录。
 */
export interface WebDavProviderCredentials {
  webDavUrl: string;
  username: string;
  password: string;
}

/**
 * 云端同步：当前选用的同步源 + GitHub / Gitee / WebDAV 各一套凭据 + 通用开关。
 */
export interface GistSyncSettings {
  /**
   * 当前使用的同步源：`github` | `gitee` | `webdav`（仅决定上传/拉取/自动同步走哪套 API）。
   */
  gistProvider: string;
  /** GitHub Gist 专用配置（与切换至 Gitee 无关，分别保存） */
  github: GistProviderCredentials;
  /** Gitee 代码片段专用配置 */
  gitee: GistProviderCredentials;
  /** WebDAV 专用配置 */
  webdav: WebDavProviderCredentials;
  /**
   * 本地书签写盘后防抖上传到云端（仍须当前源配置有效）。
   */
  autoUploadAfterEdit: boolean;
  /**
   * 切换到「收藏夹」Tab 时尝试拉取：仅当本地无「未上传的编辑」且远端 SyncDataInfo.createDate 更新时覆盖本机。
   */
  autoPullOnTabFocus: boolean;
}

export function defaultGistProviderCredentials(): GistProviderCredentials {
  return {
    gistToken: '',
    gistId: '',
    gistFileName: DEFAULT_GIST_FILE_NAME
  };
}

export function defaultWebDavProviderCredentials(): WebDavProviderCredentials {
  return {
    webDavUrl: '',
    username: '',
    password: ''
  };
}

/** 取当前同步源对应的令牌与片段字段（供网络层与校验使用） */
export function activeCredentialsFromSettings(s: GistSyncSettings): GistProviderCredentials {
  const row: GistProviderCredentials = s.gistProvider === GIST_PROVIDER_GITEE ? s.gitee : s.github;
  const fn: string = row.gistFileName.trim().length > 0 ? row.gistFileName.trim() : DEFAULT_GIST_FILE_NAME;
  return {
    gistToken: row.gistToken,
    gistId: row.gistId,
    gistFileName: fn
  };
}

/** 取 WebDAV 当前配置（供网络层与校验使用） */
export function activeWebDavCredentialsFromSettings(s: GistSyncSettings): WebDavProviderCredentials {
  return {
    webDavUrl: s.webdav.webDavUrl,
    username: s.webdav.username,
    password: s.webdav.password
  };
}

export function isWebDavProvider(s: GistSyncSettings): boolean {
  return s.gistProvider === GIST_PROVIDER_WEBDAV;
}
