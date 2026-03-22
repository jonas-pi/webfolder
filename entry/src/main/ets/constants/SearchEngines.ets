import type { SearchEngineItem } from '../model/IndexTypes';

export const SEARCH_ENGINES: Array<SearchEngineItem> = [
  { name: 'Google', prefix: 'https://www.google.com/search?q=', icon: $r('app.media.ic_se_google') },
  { name: '必应', prefix: 'https://www.bing.com/search?q=', icon: $r('app.media.ic_se_bing') },
  { name: '百度', prefix: 'https://www.baidu.com/s?wd=', icon: $r('app.media.ic_se_baidu') },
  { name: 'DuckDuckGo', prefix: 'https://duckduckgo.com/?q=', icon: $r('app.media.ic_se_ddg') },
  { name: '搜狗', prefix: 'https://www.sogou.com/web?query=', icon: $r('app.media.ic_se_sogou') },
  { name: '360搜索', prefix: 'https://www.so.com/s?q=', icon: $r('app.media.ic_se_360') },
  { name: 'Yahoo', prefix: 'https://search.yahoo.com/search?p=', icon: $r('app.media.ic_se_yahoo') },
  { name: 'Yandex', prefix: 'https://yandex.com/search/?text=', icon: $r('app.media.ic_se_yandex') },
  { name: 'Ecosia', prefix: 'https://www.ecosia.org/search?method=index&q=', icon: $r('app.media.ic_se_ecosia') }
];
