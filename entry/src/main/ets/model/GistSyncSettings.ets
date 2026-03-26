/**
 * GitHub Gist 同步凭据（与 BookmarkHub 扩展配置项对应：Token、Gist ID、文件名）。
 * 单独 JSON 持久化，不混入 settings_cache.json，避免影响现有设置解析。
 */
export interface GistSyncSettings {
  /** Personal Access Token，需勾选 gist 权限 */
  githubToken: string;
  /** Gist 的 ID（非完整 URL） */
  gistId: string;
  /** Gist 内书签文件的文件名，须与扩展中一致（默认 BookmarkHub） */
  gistFileName: string;
  /**
   * 本地书签写盘后防抖上传到 Gist（仍须 Token / Gist ID / 文件名有效）。
   * 与扩展协同时，适合「手机改完即推云端」。
   */
  autoUploadAfterEdit: boolean;
  /**
   * 切换到「收藏夹」Tab 时尝试拉取：仅当本地无「未上传的编辑」且远端 SyncDataInfo.createDate 更新时覆盖本机。
   * 应用退到后台再回前台不会触发（仅 Tab 切换）；完全后台定时同步需系统后台任务，当前未实现。
   */
  autoPullOnTabFocus: boolean;
}
