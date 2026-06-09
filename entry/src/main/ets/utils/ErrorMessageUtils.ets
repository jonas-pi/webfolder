export function errorMessageFromThrown(err: Object | string | undefined | null): string {
  if (typeof err === 'string') {
    return err.length > 0 ? err : '未知错误';
  }
  if (err === undefined || err === null) {
    return '未知错误';
  }
  const rec = err as Record<string, Object | undefined>;
  const messageVal: Object | undefined = rec['message'];
  const codeVal: Object | undefined = rec['code'];
  const message: string = typeof messageVal === 'string' ? (messageVal as string) : '';
  if (codeVal !== undefined && message.length > 0) {
    return `${codeVal}: ${message}`;
  }
  if (message.length > 0) {
    return message;
  }
  if (codeVal !== undefined) {
    return `${codeVal}`;
  }
  try {
    const text: string = JSON.stringify(err);
    if (text.length > 0 && text !== '{}') {
      return text;
    }
  } catch (_e) {
  }
  return '未知错误';
}
