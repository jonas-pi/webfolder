# 网址收藏夹

面向 **HarmonyOS（鸿蒙）** 的轻量书签应用：把电脑浏览器里导出的收藏夹带到手机上，**点一下即打开链接**，无需臃肿套件。

## 核心亮点

- **Edge / Chrome 通用导入**  
  支持 **Microsoft Edge** 与 **Google Chrome** 导出的 **HTML 书签文件**（两者均采用经典的 Netscape 书签格式，本应用按该格式解析）。在 PC 上导出收藏夹后，将 `.html` 文件导入本应用即可在鸿蒙设备上浏览相同目录结构。
- **一触即达**  
  收藏夹 Tab 中点击条目即可通过系统浏览器打开对应网址，常用站点随手可达。
- **轻量专注**  
  以书签管理与快捷打开为主，界面与依赖保持精简，适合作为「随身网址面板」使用。
- **与 BookmarkHub 协同**  
  **我的 → 云端同步** 可配置 **GitHub Gist** 或 **Gitee 代码片段**（**访问令牌、片段 ID、片段内文件名** 等）；**上传到云端 / 从云端拉取**；载荷与浏览器扩展 [BookmarkHub（衍生版）](https://github.com/jonas-pi/BookmarkHub) 相同。  
  **新建 Gist / Gitee 片段、申请令牌与字段说明** 见 **[docs/云端同步使用说明.md](docs/云端同步使用说明.md)**。

## 电脑端浏览器扩展怎么装（与鸿蒙共用 Gist）

鸿蒙应用只负责手机侧；**PC 浏览器侧**需要单独安装扩展，才能把书签同步到同一份 GitHub Gist：

| 方式 | 说明 |
|------|------|
| **商店版 BookmarkHub（上游）** | Chrome / Edge 等商店中的「BookmarkHub」多为上游作者上架版本，数据格式与本应用兼容时可互通；**与本仓库配套维护的衍生版仓库为下栏。** |
| **衍生版扩展（推荐与本应用配套）** | 源码与预编译包见 **[jonas-pi/BookmarkHub](https://github.com/jonas-pi/BookmarkHub)**：**GitHub Releases** 下载 **Chromium 扩展 zip** → 解压 → `chrome://extensions` / `edge://extensions` 开启 **开发者模式** → **加载已解压的扩展程序**（选含 `manifest.json` 的根目录）。本地构建：`npm install` → `npm run build` → 加载 **`.output/chrome-mv3`**。细节以该仓库 README 为准。 |

> 若你同时维护鸿蒙工程与扩展工程，请确保两端配置的 **访问令牌、片段 ID、片段内文件名**（及同一 **同步源**：GitHub 或 Gitee）一致；上传会覆盖远端该文件，拉取会覆盖本机缓存，首次使用前请备份。

## 功能展示

- **收藏夹**：按文件夹整理导入后的书签；右上角菜单 **导入收藏** 可选择 Edge / Chrome 导出的 HTML 文件。  
- **搜索**：多引擎搜索页；搜索框可 **临时切换** 引擎；**我的 → 搜索设置** 可设默认引擎与搜索框位置（上 / 中 / 下）。  
- **背景**：**我的 → 设置背景** 支持相册或文件（JPG / PNG / WebP / GIF）、虚化与明暗度，并可恢复默认。  
- **云端同步**：**我的 → 云端同步** 填写 **访问令牌、片段 ID、片段内文件名**（及 **同步源**）后，可上传或拉取书签（拉取会覆盖本机缓存）。可选 **编辑后自动上传**（写盘成功后约 4.5 秒防抖）、**切到收藏夹 Tab 时自动拉取**（仅当本地无未上传修改且远端 `createDate` 更新时覆盖）；应用退至后台不会定时轮询，真正后台定时同步需系统级任务能力，当前未做。详细步骤见 [docs/云端同步使用说明.md](docs/云端同步使用说明.md)。

**收藏夹 · 搜索主页**（一行三张）

| 收藏夹列表 | 导入收藏 | 搜索主页 |
| :--------: | :------: | :------: |
| <img src="docs/收藏夹页面展示.jpg" alt="收藏夹页面" width="200" /> | <img src="docs/收藏夹页面导入按钮展示.jpg" alt="收藏夹导入入口" width="200" /> | <img src="docs/搜索页面展示.jpg" alt="搜索页面" width="200" /> |

| 临时切换搜索引擎 | 搜索设置 | 设置背景 |
| :--------------: | :------: | :------: |
| <img src="docs/临时切换搜索引擎展示.jpg" alt="临时切换搜索引擎" width="200" /> | <img src="docs/切换默认搜索引擎展示.jpg" alt="搜索设置：默认引擎与搜索框位置" width="200" /> | <img src="docs/更换背景展示.jpg" alt="设置背景" width="200" /> |

## 在 Edge / Chrome 中导出收藏夹（HTML）

1. **Edge**：在 **设置** 或 **收藏夹 / 收藏夹管理** 相关页面中，选择将收藏夹 **导出为 HTML 文件**（不同版本菜单位置可能略有差异）。  
2. **Chrome**：打开 **书签管理器**（菜单或地址栏输入 `chrome://bookmarks`），通过菜单将书签 **导出为 HTML 文件**。

> 若其他 Chromium 系浏览器同样导出为上述 HTML 格式，一般也可导入使用。

## 安装方式

本应用已在 **华为应用市场（AppGallery）** 上架。请在鸿蒙设备上打开 **应用市场** 搜索安装，或直达详情页：

**[华为应用市场 — com.jonas.webbookmarks](https://appgallery.huawei.com/app/detail?id=com.jonas.webbookmarks&channelId=SHARE&source=appshare)**

## 开发说明

- **工程类型**：HarmonyOS 应用（ArkTS / ArkUI）。
- **包名**：`com.jonas.webbookmarks`（见 `AppScope/app.json5`）。
- **构建**：使用 DevEco Studio 打开本目录，按官方流程编译与签名安装。
- **书签缓存格式**：本地 `bookmarks_cache.json` 采用与浏览器扩展 [BookmarkHub（衍生版）](https://github.com/jonas-pi/BookmarkHub) 相同的 `SyncDataInfo` 树形结构（`MenuFolder` / `ToolbarFolder` / `UnfiledFolder` / `MobileFolder` 四根），便于与扩展共用同一云端片段文件。界面仍使用扁平路径（如 `收藏夹栏 / …`、`未分类`、`书签菜单` 表示菜单根下直连链接）；**旧版纯 JSON 数组**会在首次加载时自动按等价语义解析，下次保存即写入新格式。

## 权限说明

- **网络**：用于站点图标等可选网络能力（以工程 `module.json5` 为准）。
- **振动**：用于轻量触感反馈（可在系统设置中管理）。

---

在鸿蒙上延续你在 Edge / Chrome 里的收藏习惯，**导入一次，随身一点即开**。
