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
  **我的 → 云端同步** 可配置 GitHub Token 与 Gist，**上传到 Gist / 从 Gist 拉取**；载荷与浏览器扩展 [BookmarkHub](https://github.com/dudor/BookmarkHub) 相同，可与电脑浏览器书签共用一份 Secret Gist。

## 电脑端浏览器扩展怎么装（与鸿蒙共用 Gist）

鸿蒙应用只负责手机侧；**PC 浏览器侧**需要单独安装扩展，才能把书签同步到同一份 GitHub Gist：

| 方式 | 说明 |
|------|------|
| **官方 BookmarkHub** | 若你在 **Chrome / Edge 等商店**安装的是原作者 [dudor/BookmarkHub](https://github.com/dudor/BookmarkHub) 上架版本，按各商店的安装说明即可；与本应用使用相同的 Gist 格式即可互通。 |
| **衍生版扩展（半自动同步等）** | 若你使用的是带 **定时拉取、变更后防抖上传、与鸿蒙端 createDate / dirty 策略对齐** 等能力的衍生版，通常**未在应用商店发布**。优先看该仓库 **GitHub Releases**：下载附件中的 **Chromium 扩展 zip** → **解压**到文件夹 → 在 `chrome://extensions` / `edge://extensions` 打开 **开发者模式** → **加载已解压的扩展程序**，选中 **根目录下含有 `manifest.json` 的那一层文件夹**（若 zip 里多套一层目录，选内层带清单的目录）。若无 Release 或需改源码，再 **本地构建**：Node.js → 克隆仓库 → `npm install` → `npm run build` → 加载 **`.output/chrome-mv3`**。**Firefox、更新方式与本地打 zip 等细节以该扩展 README 的「安装 / Installation」为准。** |

> 若你同时维护鸿蒙工程与扩展工程，请确保两端配置的 **Token、Gist ID、文件名** 一致；上传会覆盖 Gist，拉取会覆盖本机缓存，首次使用前请备份。

## 功能展示

- **收藏夹**：按文件夹整理导入后的书签；右上角菜单 **导入收藏** 可选择 Edge / Chrome 导出的 HTML 文件。  
- **搜索**：多引擎搜索页；搜索框可 **临时切换** 引擎；**我的 → 搜索设置** 可设默认引擎与搜索框位置（上 / 中 / 下）。  
- **背景**：**我的 → 设置背景** 支持相册或文件（JPG / PNG / WebP / GIF）、虚化与明暗度，并可恢复默认。  
- **云端同步**：**我的 → 云端同步** 填写与 BookmarkHub 一致的 Token、Gist ID 与文件名后，可上传或拉取书签（拉取会覆盖本机缓存）。可选 **编辑后自动上传**（写盘成功后约 4.5 秒防抖）、**切到收藏夹 Tab 时自动拉取**（仅当本地无未上传修改且远端 `createDate` 更新时覆盖）；应用退至后台不会定时轮询，真正后台定时同步需系统级任务能力，当前未做。

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

1. 在 **[Releases](https://github.com/jonas-pi/webfolder/releases)** 下载最新 **`entry-default-unsigned.hap`**（本仓库提供的是**未签名**调试包，便于自行安装体验）。  
   - 固定直链（始终指向最新一次 Release 中的同名附件）：  
     [https://github.com/jonas-pi/webfolder/releases/latest/download/entry-default-unsigned.hap](https://github.com/jonas-pi/webfolder/releases/latest/download/entry-default-unsigned.hap)

2. 将 HAP 安装到 **HarmonyOS NEXT** 等设备上，推荐使用 **小白调试助手**（开源 HAP 安装工具，原项目名 Auto-Installer）：  
   **[https://github.com/likuai2010/auto-installer](https://github.com/likuai2010/auto-installer)**  
   按该仓库说明在 Windows / macOS / Linux 等环境连接设备后安装即可（具体步骤以工具文档为准）。

## 开发说明

- **工程类型**：HarmonyOS 应用（ArkTS / ArkUI）。
- **包名**：`com.jonas.webbookmarks`（见 `AppScope/app.json5`）。
- **构建**：使用 DevEco Studio 打开本目录，按官方流程编译与签名安装。
- **书签缓存格式**：本地 `bookmarks_cache.json` 采用与浏览器扩展 [BookmarkHub](https://github.com/dudor/BookmarkHub) 相同的 `SyncDataInfo` 树形结构（`MenuFolder` / `ToolbarFolder` / `UnfiledFolder` / `MobileFolder` 四根），便于与扩展共用同一 GitHub Gist 文件。界面仍使用扁平路径（如 `收藏夹栏 / …`、`未分类`、`书签菜单` 表示菜单根下直连链接）；**旧版纯 JSON 数组**会在首次加载时自动按等价语义解析，下次保存即写入新格式。

## 权限说明

- **网络**：用于站点图标等可选网络能力（以工程 `module.json5` 为准）。
- **振动**：用于轻量触感反馈（可在系统设置中管理）。

---

在鸿蒙上延续你在 Edge / Chrome 里的收藏习惯，**导入一次，随身一点即开**。
