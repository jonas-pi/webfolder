import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

/** 隐私政策全文（GitHub Pages，与 README 说明一致） */
export const PRIVACY_POLICY_PAGE_URL: string = 'https://jonas-pi.github.io/webfolder/privacy.html';

/** Preferences 存储名（应用内隔离，勿与其它模块重名） */
const PREF_STORE_NAME: string = 'webbookmarks_app_prefs';

/**
 * 隐私同意标记键；若日后隐私政策重大变更需再次弹窗，可 bump 版本号（如 v2）并视为未同意。
 */
const KEY_PRIVACY_POLICY_ACCEPTED_V1: string = 'privacy_policy_accepted_v1';

/**
 * 是否已在首次启动流程中同意隐私政策（持久化）。
 */
export async function hasAcceptedPrivacyPolicy(context: common.Context): Promise<boolean> {
  try {
    const pref = await preferences.getPreferences(context, PREF_STORE_NAME);
    const val = await pref.get(KEY_PRIVACY_POLICY_ACCEPTED_V1, false);
    return val === true;
  } catch (_e) {
    return false;
  }
}

/**
 * 用户点击「同意」后写入；flush 保证进程异常退出前尽量落盘。
 */
export async function setPrivacyPolicyAccepted(context: common.Context, accepted: boolean): Promise<void> {
  const pref = await preferences.getPreferences(context, PREF_STORE_NAME);
  await pref.put(KEY_PRIVACY_POLICY_ACCEPTED_V1, accepted);
  await pref.flush();
}
