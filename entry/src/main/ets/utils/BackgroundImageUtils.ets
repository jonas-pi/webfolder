/**
 * 根据选择器返回的路径/URI 推断保存到本地的文件扩展名（用于保留 GIF 等动图格式）。
 */
export function inferBackgroundFileSuffix(selectedUri: string, normalizedPath: string): string {
  const s: string = (normalizedPath.length > 0 ? normalizedPath : selectedUri).toLowerCase();
  if (s.endsWith('.gif')) {
    return '.gif';
  }
  if (s.endsWith('.webp')) {
    return '.webp';
  }
  if (s.endsWith('.jpeg')) {
    return '.jpg';
  }
  if (s.endsWith('.jpg')) {
    return '.jpg';
  }
  if (s.endsWith('.png')) {
    return '.png';
  }
  return '.png';
}

/** 是否为 GIF 背景路径（用于可选的显示策略） */
export function isBackgroundGifPath(fileUriOrPath: string): boolean {
  return fileUriOrPath.toLowerCase().includes('.gif');
}
