import type { GistSyncSettings } from '../model/GistSyncSettings';
import {
  activeCredentialsFromSettings,
  activeWebDavCredentialsFromSettings,
  GIST_PROVIDER_GITEE,
  isWebDavProvider
} from '../model/GistSyncSettings';
import {
  githubFetchGistRaw,
  extractGistFileText as githubExtractGistFileText,
  githubPatchGistFiles
} from './GithubGistApi';
import {
  giteeFetchGistRaw,
  giteeExtractGistFileText,
  giteePatchGistFiles
} from './GiteeGistApi';
import { webDavFetchFileText, webDavPutFileText } from './WebDavSyncApi';

function useGitee(settings: GistSyncSettings): boolean {
  return settings.gistProvider === GIST_PROVIDER_GITEE;
}

export async function remoteFetchGistRaw(settings: GistSyncSettings): Promise<string> {
  if (isWebDavProvider(settings)) {
    const w = activeWebDavCredentialsFromSettings(settings);
    return webDavFetchFileText(w.webDavUrl, w.username, w.password);
  }
  const a = activeCredentialsFromSettings(settings);
  const token: string = a.gistToken.trim();
  const gid: string = a.gistId.trim();
  if (useGitee(settings)) {
    return giteeFetchGistRaw(token, gid);
  }
  return githubFetchGistRaw(token, gid);
}

export async function remoteExtractGistFileText(
  settings: GistSyncSettings,
  gistJson: string,
  fileName: string
): Promise<string> {
  if (isWebDavProvider(settings)) {
    return gistJson;
  }
  const token: string = activeCredentialsFromSettings(settings).gistToken.trim();
  if (useGitee(settings)) {
    return giteeExtractGistFileText(token, gistJson, fileName);
  }
  return githubExtractGistFileText(token, gistJson, fileName);
}

export async function remotePatchGistFiles(
  settings: GistSyncSettings,
  fileName: string,
  fileContent: string
): Promise<void> {
  if (isWebDavProvider(settings)) {
    const w = activeWebDavCredentialsFromSettings(settings);
    await webDavPutFileText(w.webDavUrl, w.username, w.password, fileContent);
    return;
  }
  const a = activeCredentialsFromSettings(settings);
  const token: string = a.gistToken.trim();
  const gid: string = a.gistId.trim();
  if (useGitee(settings)) {
    await giteePatchGistFiles(token, gid, fileName, fileContent);
    return;
  }
  await githubPatchGistFiles(token, gid, fileName, fileContent);
}
