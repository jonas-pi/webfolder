import type { SettingsCache } from '../model/IndexTypes';

export interface SettingsStateSnapshot {
  backgroundImagePath: string;
  backgroundBlurLevel: number;
  backgroundBrightnessLevel: number;
  searchEngineIndex: number;
  searchBoxPosition: number;
}

export function buildSettingsCache(snapshot: SettingsStateSnapshot): SettingsCache {
  return {
    backgroundImagePath: snapshot.backgroundImagePath,
    backgroundBlurLevel: `${snapshot.backgroundBlurLevel}`,
    backgroundBrightnessLevel: `${snapshot.backgroundBrightnessLevel}`,
    searchEngineIndex: `${snapshot.searchEngineIndex}`,
    searchBoxPosition: `${snapshot.searchBoxPosition}`
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
  return patch;
}
