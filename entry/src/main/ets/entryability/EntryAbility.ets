import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

/** 与页面标题栏 `sys.color.ohos_id_color_sub_background` 解析失败时的兜底（浅色/深色） */
const STATUS_BAR_BG_FALLBACK_LIGHT: string = '#FFF5F5F5';
const STATUS_BAR_BG_FALLBACK_DARK: string = '#FF1C1C1E';

/** $r 返回的资源对象在 Ability 侧无 Resource 类型导出，仅取 id 供 getColorSync */
interface ColorResourceRef {
  id: number;
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  /**
   * resourceManager 返回的颜色整数（通常为 0xAARRGGBB）转为 setWindowSystemBarProperties 使用的 #AARRGGBB 字符串
   */
  private colorIntToArgbHex(color: number): string {
    const a = (color >>> 24) & 0xFF;
    const r = (color >>> 16) & 0xFF;
    const g = (color >>> 8) & 0xFF;
    const b = color & 0xFF;
    const to2 = (n: number): string => n.toString(16).padStart(2, '0');
    return `#${to2(a)}${to2(r)}${to2(g)}${to2(b)}`;
  }

  /** 状态栏 / 底部系统导航条背景与标题栏 `ohos_id_color_sub_background` 一致；内容色随深浅色 */
  private applyStatusBarChrome(mainWindow: window.Window, config?: Configuration): void {
    const cfg: Configuration = config ?? this.context.config;
    const isDark: boolean = cfg.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    let chromeBg: string = isDark ? STATUS_BAR_BG_FALLBACK_DARK : STATUS_BAR_BG_FALLBACK_LIGHT;
    try {
      const subBgRes = $r('sys.color.ohos_id_color_sub_background');
      const colorNum: number = this.context.resourceManager.getColorSync(
        (subBgRes as ColorResourceRef).id
      );
      chromeBg = this.colorIntToArgbHex(colorNum);
    } catch (err) {
      hilog.warn(DOMAIN, 'testTag', 'getColorSync sub_background fallback: %{public}s', JSON.stringify(err));
    }
    const onLightBg: string = '#E5000000';
    const onDarkBg: string = '#E5FFFFFF';
    const systemBarProperties: window.SystemBarProperties = {
      statusBarColor: chromeBg,
      navigationBarColor: chromeBg,
      statusBarContentColor: isDark ? onDarkBg : onLightBg,
      navigationBarContentColor: isDark ? onDarkBg : onLightBg
    };
    mainWindow.setWindowSystemBarProperties(systemBarProperties).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'Failed to set system bar properties. Cause: %{public}s', JSON.stringify(err));
    });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.getMainWindow().then((mainWindow: window.Window) => {
      mainWindow.setWindowLayoutFullScreen(true).catch((err: Error) => {
        hilog.error(DOMAIN, 'testTag', 'Failed to set fullscreen layout. Cause: %{public}s', JSON.stringify(err));
      });
      this.applyStatusBarChrome(mainWindow);
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'Failed to get main window. Cause: %{public}s', JSON.stringify(err));
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    window.getLastWindow(this.context).then((mainWindow: window.Window) => {
      this.applyStatusBarChrome(mainWindow, newConfig);
    }).catch((err: Error) => {
      hilog.warn(DOMAIN, 'testTag', 'onConfigurationUpdate getLastWindow: %{public}s', JSON.stringify(err));
    });
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}