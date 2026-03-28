# 网址收藏夹

鸿蒙 **HarmonyOS NEXT** 轻量书签：导入 Edge / Chrome 导出的 **HTML 收藏夹**，点按即由系统浏览器打开；支持多引擎搜索、自定义背景与 **GitHub Gist / Gitee 代码片段** 云端同步（载荷与浏览器扩展 [BookmarkHub 衍生版](https://github.com/jonas-pi/BookmarkHub) 一致，扩展亦支持 **Gitee**，见该仓库说明；国内镜像 [Gitee](https://gitee.com/Jonas-yews/BookmarkHub)）。

## 安装

**[华为应用市场 — com.jonas.webbookmarks](https://appgallery.huawei.com/app/detail?id=com.jonas.webbookmarks&channelId=SHARE&source=appshare)**

## 主要功能

- **导入：** 收藏夹 Tab → 菜单 **导入收藏**，选择 `.html`（Netscape 书签格式）。
- **搜索 / 背景：** **我的** 中搜索设置、设置背景（图片、虚化、明暗度）。
- **云端同步：** **我的 → 云端同步** 配置令牌、片段 ID、文件名与 **同步源（GitHub 或 Gitee）**；可选编辑后自动上传、切回收藏夹 Tab 时自动拉取。细则见 [docs/云端同步使用说明.md](docs/云端同步使用说明.md)。**上传覆盖远端、拉取覆盖本机缓存**，首次请备份。
- **PC 浏览器配套：** 需单独安装上述 **BookmarkHub 衍生版** 扩展（[GitHub](https://github.com/jonas-pi/BookmarkHub/releases) / [Gitee 发行版](https://gitee.com/Jonas-yews/BookmarkHub/releases) 下载 zip 加载），两端令牌、片段 ID、文件名及同步源须一致。

## 截图

| 收藏夹 | 导入 | 搜索 |
| :---: | :---: | :---: |
| <img src="docs/收藏夹页面展示.jpg" width="200" /> | <img src="docs/收藏夹页面导入按钮展示.jpg" width="200" /> | <img src="docs/搜索页面展示.jpg" width="200" /> |

| 切换搜索引擎 | 搜索设置 | 背景 |
| :---: | :---: | :---: |
| <img src="docs/临时切换搜索引擎展示.jpg" width="200" /> | <img src="docs/切换默认搜索引擎展示.jpg" width="200" /> | <img src="docs/更换背景展示.jpg" width="200" /> |

## 在电脑导出 HTML 书签

**Edge：** 设置或收藏夹相关页 → **导出为 HTML**。**Chrome：** `chrome://bookmarks` → 菜单导出 HTML。其它 Chromium 浏览器若导出同格式，一般也可导入。

## 开发

HarmonyOS ArkTS / ArkUI；包名 `com.jonas.webbookmarks`。用 **DevEco Studio** 打开本目录构建。本地 `bookmarks_cache.json` 为 `SyncDataInfo` 树（与扩展一致）；旧版扁平 JSON 首次打开会迁移。

**权限（见 `module.json5`）：** 网络（如 favicon）、振动（触感）。
