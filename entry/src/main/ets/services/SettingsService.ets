import type { SettingsCache } from '../model/IndexTypes';

export interface SettingsStateSnapshot {
  backgroundImagePath: string;
  backgroundBlurLevel: number;
  backgroundBrightnessLevel: number;
  searchEngineIndex: number;
  searchBoxPosition: number;
  /**
   * 标题栏副背景延伸至状态栏区域（系统栏透明）；关闭时为独立顶占位 + 系统栏实色。
   * 未传时按 true 处理。
   */
  immersiveEdgeLight?: boolean;
}

export function buildSettingsCache(snapshot: SettingsStateSnapshot): SettingsCache {
  const immersive: boolean = snapshot.immersiveEdgeLight !== false;
  return {
    backgroundImagePath: snapshot.backgroundImagePath,
    backgroundBlurLevel: `${snapshot.backgroundBlurLevel}`,
    backgroundBrightnessLevel: `${snapshot.backgroundBrightnessLevel}`,
    searchEngineIndex: `${snapshot.searchEngineIndex}`,
    searchBoxPosition: `${snapshot.searchBoxPosition}`,
    immersiveEdgeLight: immersive ? '1' : '0'
  };
}

export function applySettingsCache(
  restored: SettingsCache,
  searchEngineCount: number
): Partial<SettingsStateSnapshot> {
  const patch: Partial<SettingsStateSnapshot> = {};
  if (restored.backgroundImagePath !== undefined) {
    if (restored.backgroundImagePath.startsWith('file://')) {
      patch.backgroundImagePath = restored.backgroundImagePath;
    } else if (restored.backgroundImagePath.length > 0) {
      patch.backgroundImagePath = `file://${restored.backgroundImagePath}`;
    } else {
      patch.backgroundImagePath = '';
    }
  }
  if (restored.backgroundBlurLevel !== undefined) {
    const parsedBlur: number = Number(restored.backgroundBlurLevel);
    if (!Number.isNaN(parsedBlur)) {
      patch.backgroundBlurLevel = parsedBlur;
    }
  }
  if (restored.backgroundBrightnessLevel !== undefined) {
    const parsedBrightness: number = Number(restored.backgroundBrightnessLevel);
    if (!Number.isNaN(parsedBrightness)) {
      patch.backgroundBrightnessLevel = parsedBrightness;
    }
  }
  if (restored.searchEngineIndex !== undefined) {
    const parsedSe: number = Number(restored.searchEngineIndex);
    if (!Number.isNaN(parsedSe) && parsedSe >= 0 && parsedSe < searchEngineCount) {
      patch.searchEngineIndex = parsedSe;
    }
  }
  if (restored.searchBoxPosition !== undefined) {
    const parsedPos: number = Number(restored.searchBoxPosition);
    if (parsedPos === 0 || parsedPos === 1 || parsedPos === 2) {
      patch.searchBoxPosition = parsedPos;
    }
  }
  if (restored.immersiveEdgeLight !== undefined) {
    const raw: string = restored.immersiveEdgeLight;
    patch.immersiveEdgeLight = raw === '1' || raw === 'true';
  }
  return patch;
}
