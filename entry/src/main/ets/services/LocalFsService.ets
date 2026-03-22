import fs from '@ohos.file.fs';
import util from '@ohos.util';

export function canAccessPath(pathOrUri: string): boolean {
  try {
    fs.accessSync(pathOrUri);
    return true;
  } catch (_) {
    return false;
  }
}

export function normalizePickerUriToPath(uri: string): string {
  if (uri.startsWith('file://')) {
    const rawPath: string = uri.substring('file://'.length);
    const decodedPath: string = decodeURIComponent(rawPath);
    if (decodedPath.startsWith('/')) {
      return decodedPath;
    }
    return `/${decodedPath}`;
  }
  return uri;
}

export function readTextByFd(pathOrUri: string): string {
  const file: fs.File = fs.openSync(pathOrUri, fs.OpenMode.READ_ONLY);
  const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
  let content: string = '';
  try {
    const bufferSize: number = 64 * 1024;
    const buffer: ArrayBuffer = new ArrayBuffer(bufferSize);
    let readBytes: number = fs.readSync(file.fd, buffer);
    while (readBytes > 0) {
      const chunk: Uint8Array = new Uint8Array(buffer, 0, readBytes);
      content += decoder.decode(chunk);
      readBytes = fs.readSync(file.fd, buffer);
    }
    return content;
  } finally {
    fs.closeSync(file);
  }
}

export function copyByFd(sourcePathOrUri: string, destPath: string): void {
  const source: fs.File = fs.openSync(sourcePathOrUri, fs.OpenMode.READ_ONLY);
  const dest: fs.File = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    const bufferSize: number = 64 * 1024;
    const buffer: ArrayBuffer = new ArrayBuffer(bufferSize);
    let readBytes: number = fs.readSync(source.fd, buffer);
    while (readBytes > 0) {
      const chunkBuffer: ArrayBuffer = new ArrayBuffer(readBytes);
      const chunkView: Uint8Array = new Uint8Array(chunkBuffer);
      chunkView.set(new Uint8Array(buffer, 0, readBytes));
      fs.writeSync(dest.fd, chunkBuffer);
      readBytes = fs.readSync(source.fd, buffer);
    }
  } finally {
    fs.closeSync(source);
    fs.closeSync(dest);
  }
}

export async function readBookmarkFileText(uri: string, cacheDir: string): Promise<string> {
  try {
    return await fs.readText(uri);
  } catch (_) {
    const localPath: string = normalizePickerUriToPath(uri);
    try {
      return await fs.readText(localPath);
    } catch (_) {
      const tempPath: string = `${cacheDir}/bookmark_import_${Date.now()}.html`;
      try {
        await fs.copyFile(uri, tempPath);
        return await fs.readText(tempPath);
      } catch (_) {
        try {
          await fs.copyFile(localPath, tempPath);
          return await fs.readText(tempPath);
        } catch (_) {
          try {
            return readTextByFd(uri);
          } catch (_) {
            return readTextByFd(localPath);
          }
        }
      }
    }
  }
}

export function writeTextFile(path: string, payload: string): void {
  const file: fs.File = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, payload);
  } finally {
    fs.closeSync(file);
  }
}
