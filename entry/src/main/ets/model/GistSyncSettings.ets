/** 与 GitHub Gist / BookmarkHub 扩展一致 */
export const GIST_PROVIDER_GITHUB: string = 'github';
/** Gitee 代码片段（OpenAPI v5，国内访问更稳定） */
export const GIST_PROVIDER_GITEE: string = 'gitee';

/** 默认片段内文件名（与扩展默认一致） */
export const DEFAULT_GIST_FILE_NAME: string = 'BookmarkHub';

/**
 * 单一云端（GitHub 或 Gitee）下的令牌与片段定位；两套配置独立持久化。
 */
export interface GistProviderCredentials {
  gistToken: string;
  gistId: string;
  gistFileName: string;
}

/**
 * 云端同步：当前选用的同步源 + GitHub / Gitee 各一套凭据 + 通用开关。
 */
export interface GistSyncSettings {
  /**
   * 当前使用的同步源：`github` | `gitee`（仅决定上传/拉取/自动同步走哪套 API）。
   */
  gistProvider: string;
  /** GitHub Gist 专用配置（与切换至 Gitee 无关，分别保存） */
  github: GistProviderCredentials;
  /** Gitee 代码片段专用配置 */
  gitee: GistProviderCredentials;
  /**
   * 本地书签写盘后防抖上传到云端（仍须当前源下 Token / 片段 ID / 文件名有效）。
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
