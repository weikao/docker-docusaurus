# Docusaurus 生产 Docker（启动时编译，重启即发布）

基于 [Docusaurus](https://docusaurus.io/) 的生产级文档站点方案：

- **启动即编译**：容器启动时编译挂载的站点源码，然后由 Nginx 提供服务
- **改 md 即发布**：编辑文档后执行 `docker compose restart docusaurus`，无需重建镜像
- **产品版本并存**：文档版本与产品版本对应（1.0 / 2.0），复制模板文件即可冻结历史版本
- **版本即镜像 tag**：Docusaurus 升级 = 拉取新镜像
- **国内源**：DaoCloud 基础镜像 + 淘宝 npm 源 + 阿里云 alpine 源，全流程无外网压力

> 镜像内已预装全部依赖，启动编译很快：首次约 60 秒（含编译），有缓存时约 10 秒。

## 目录结构

```
docker-docusaurus/
├── docker-compose.yml   # 编排：生产服务 + 开发热更新
├── Dockerfile           # 生产镜像（node + nginx，启动时编译）
├── entrypoint.sh        # 启动脚本：同步源码 → 编译 → 启动 nginx
├── nginx.conf           # 生产级 nginx 配置（gzip + 缓存策略）
├── build.bat / build.sh # 维护者发版脚本（构建并推送镜像）
├── build-hub.bat        # 发布到 Docker Hub（版本取自 .env）
├── .env                 # 版本号 / 镜像名等配置
└── site/                # ★ 站点源码（docs、blog、配置都在这里）
    ├── docs/            # 文档 Markdown（日常只改这里）
    ├── docs/api/        # OpenAPI 生成的 API 文档（勿手改）
    ├── openapi/         # OpenAPI 规范文件（API 文档的唯一数据源）
    ├── RELEASE.txt.example  # 发布新版本文档的模板（复制为 RELEASE.txt 使用）
    └── versioned_docs/  # 历史版本的冻结文档（发布后自动生成）
```

## 已集成插件

| 插件 | 功能 |
|------|------|
| @easyops-cn/docusaurus-search-local | 导航栏本地搜索，支持中文分词，离线可用 |
| sitemap（preset 内置） | 自动生成 `/sitemap.xml` |
| docusaurus-plugin-image-zoom | 文档图片点击放大 |
| docusaurus-plugin-llms | 构建时生成 `/llms.txt` 与 `/llms-full.txt`（面向 AI/LLM） |
| docusaurus-plugin-cookie-consent | Cookie 同意提示（底部 toast，中文文案） |
| docusaurus-plugin-openapi-docs + theme | 从 OpenAPI 规范生成交互式 API 文档 |

## 快速开始

```bash
# 首次构建镜像并启动（约 2 分钟）
docker compose up -d --build docusaurus

# 查看状态（等待 healthy 即编译完成）
docker compose ps
```

访问 `http://localhost:8080`。

## 日常发布内容（核心工作流）

```bash
# 1. 编辑 site/docs/ 下的 Markdown
# 2. 重启容器，启动时自动编译新内容（约 10 秒）
docker compose restart docusaurus
```

完成，新内容已上线。无需任何编译脚本、无需重建镜像。

> 依赖以镜像为准：修改宿主机 `site/package.json` 不影响生产容器（仅影响 dev 服务）；
> 需要增删插件/依赖时，由维护者更新清单后重新发版镜像。

## 站点配置（标题 / SEO / 图标 / 部署路径）

站点元数据支持通过 `docker-compose.yml` 顶部的 `x-site-config` 环境变量配置
（由启动时编译读取，全部可选，不设置则用 `site/docusaurus.config.js` 中的默认值）：

| 环境变量 | 作用 |
|----------|------|
| `SITE_TITLE` | 站点标题（`<title>`、og:title、导航栏、页脚） |
| `SITE_TAGLINE` | 副标题（同时作为全局 description） |
| `SITE_URL` | 部署域名，canonical / sitemap.xml / og:url 均基于它生成 |
| `SITE_BASE_URL` | 部署子路径，如部署到 `https://x.com/docs/` 时设为 `/docs/` |
| `SITE_FAVICON` | 标签图标路径，指向 `site/static/` 下的文件 |
| `SITE_LOGO` | 导航栏 Logo 路径（如 `/img/logo.png`），留空/不设置则不显示 |
| `SITE_LOCALE` | 站点语言（默认 `zh-Hans`，影响 `<html lang>` 与界面文案） |
| `SITE_KEYWORDS` | SEO 关键词 |
| `SITE_NAVBAR_TITLE` | 导航栏标题（默认同 `SITE_TITLE`） |
| `SITE_FOOTER_COPYRIGHT` | 页脚版权文案 |

```bash
# 修改 docker-compose.yml 中的 x-site-config 后，重建容器即生效（无需重建镜像）
docker compose up -d docusaurus
```

> 自定义图标：把文件放到 `site/static/img/` 下（如 `logo.png`），并设置
> `SITE_FAVICON: /img/logo.png`（标签图标）或 `SITE_LOGO: /img/logo.png`（导航栏 Logo）。
> 静态资源目录 `site/static/` 会原样发布到站点根路径。

## 文档版本（与产品版本对应）

这个平台用于撰写产品说明：**文档版本就是产品版本**——产品发布 1.0，
文档就有一份 1.0；产品升级到 2.0，再冻结一份 2.0，1.0 的说明书继续给老用户看。

日常写文档只需要关注 `site/docs/`，它永远对应**线上最新版**（`/docs`）。
只有在产品发布新版本、需要把当前文档定格为历史版本时，才用到下面的操作。

> 全程无需命令行参数、无需在电脑上安装任何开发环境，重启容器即可（与日常发布一样）。

### 发布新版本（产品上线新版本时）

| 步骤 | 操作 |
|------|------|
| 1 | 把 `site/RELEASE.txt.example` 复制一份，重命名为 `site/RELEASE.txt` |
| 2 | 打开它，把最下方的版本号改成产品版本（如 `2.0`） |
| 3 | 重启容器：`docker compose restart docusaurus`（和平时发布文档完全一样） |

完成。容器启动时会自动：

- 把当前 `site/docs/` 冻结为该版本，保存到 `site/versioned_docs/version-2.0/`
- 删除 `RELEASE.txt`（一次性指令，不会重复执行）
- 编译并上线，导航栏自动出现版本切换菜单（未发布过版本时则自动隐藏）

发布后的访问地址：

| 内容 | 位置 | 线上地址 |
|------|------|----------|
| 最新版（继续编辑 `site/docs/`） | `site/docs/` | `/docs` |
| 历史版本 2.0 | `site/versioned_docs/version-2.0/` | `/docs/2.0` |
| 历史版本 1.0 | `site/versioned_docs/version-1.0/` | `/docs/1.0` |

历史版本页面顶部会显示"不再维护"提示并链接到最新版；线上 `/docs` 始终展示最新文档，
日常写作流程完全不变。

### 发布失败时

若发布没有生效，`site/` 下会出现 `RELEASE.txt.failed` 文件，常见原因：

- **版本号已存在**：换一个版本号（或先删除旧版本，见下文）
- **没填版本号 / 版本号含非法字符**：版本号仅限字母、数字和 `. _ -`（如 `1.0`、`2.5`、`v3`）

查看原因：`docker compose logs docusaurus`。修正后重新创建 `RELEASE.txt` 再重启即可。

### 修订历史版本

发现老版本的文档写错了？直接编辑 `site/versioned_docs/version-<版本>/` 下的 Markdown，
然后照常 `docker compose restart docusaurus`——只影响该历史版本，最新版不受影响。

### 删除历史版本

在 `site/versions.json` 中删除对应版本名那一行，再删除
`site/versioned_docs/version-<版本>/` 与 `site/versioned_sidebars/version-<版本>-sidebars.json`，
重启容器生效。（历史版本数量建议保持在 10 个以内，太久远的版本可直接删除。）

### 进阶配置（维护者可选）

版本行为的少量开关已做成环境变量，在 `docker-compose.yml` 的 `x-site-config` 中配置，
修改后 `docker compose up -d docusaurus` 重建容器生效，业务人员无需关心：

| 环境变量 | 默认 | 作用 |
|----------|------|------|
| `SITE_DOCS_LAST_VERSION` | `current` | 最新版指向（占据 `/docs`）。默认当前文档即最新版；设为分版名（如 `2.0`）则 `site/docs/` 变为"下一版开发中"，仅在 `/docs/next` 可见 |
| `SITE_DOCS_INCLUDE_CURRENT` | `true` | 当前文档尚未定稿、暂不对外发布时设为 `false`（注意：从未发布过版本时不能设为 `false`，否则站点没有可发布内容） |
| `SITE_DOCS_CURRENT_LABEL` | `Current` | 当前版本在下拉菜单 / 徽章中的标签 |
| `SITE_DOCS_CURRENT_PATH` | 自动 | 当前版本 URL 路径（默认最新版为 `/docs`，否则 `/docs/next`） |
| `SITE_DOCS_VERSION_DROPDOWN` | 自动 | 导航栏版本下拉菜单；`true`/`false` 强制开/关，留空则发布过版本后自动显示 |

## 内容开发（可选，热更新预览）

写文档时可用 dev 服务实时预览（3000 端口），与生产服务互不干扰：

```bash
docker compose up -d dev     # 启动开发服务
# 浏览器打开 http://localhost:3000，保存文件秒级热更新
docker compose stop dev      # 不用时停止
```

## 版本升级

### 维护者发版

```bash
# Windows
build.bat 3.10.3

# Linux / macOS
./build.sh 3.10.3

# 构建并推送到镜像仓库（生产推荐）
build.bat 3.10.3 registry.example.com/my/docs-site push

# 发布到 Docker Hub（版本自动读取 .env 的 DOCUSAURUS_VERSION，需先 docker login）
# 仓库名优先取参数，其次 .env 的 DOCKERHUB_REPO，最后 IMAGE_NAME
build-hub.bat myname/docusaurus-site
```

> 首次发布到 Docker Hub 后，把 `DOCKERHUB.md` 的内容粘贴到仓库页面的
> "Full description"，作为使用者的部署说明。

脚本会同步 `site/package.json` 中 `@docusaurus/*` 依赖版本，构建并打上
`<版本>` 与 `latest` 两个 tag（加 `push` 参数时推送到仓库）。

### GitHub Actions 自动发布

已提供 `.github/workflows/publish-docker.yml`，自动构建并推送镜像到 GHCR
（`ghcr.io/<owner>/docusaurus-site`）：

```bash
# 推荐：打 tag 触发发布（如发布 3.10.3）
git tag v3.10.3 && git push origin v3.10.3
```

也可以在 Actions 页面手动触发（workflow_dispatch，输入版本号）；推送到
`main` 分支仅做构建验证，不推送镜像。首次发布后需在仓库 Settings →
Packages 中将包可见性改为 Public（或在使用侧配置拉取凭证）。

### 使用者升级

```bash
# 修改 .env 中 DOCUSAURUS_VERSION 为新版本，然后：
docker compose pull docusaurus
docker compose up -d docusaurus
```

依赖（含 Docusaurus 本体）烘焙在镜像内，拉取新镜像即完成升级；
容器重启时会自动用新版本重新编译文档。

## 自定义站点

所有站点相关文件都在 `site/` 目录：

| 文件 | 说明 |
|------|------|
| `site/docusaurus.config.js` | 站点核心配置（标题、导航、主题） |
| `site/sidebars.js` | 文档侧边栏 |
| `site/docs/` | 文档内容（Markdown/MDX） |
| `site/blog/` | 博客内容 |
| `site/src/` | 自定义页面与组件 |
| `site/static/` | 静态资源 |
| `site/openapi/sample.json` | OpenAPI 规范（API 文档数据源，替换为你自己的） |

修改任意文件后 `docker compose restart docusaurus` 即生效。

## API 文档维护（OpenAPI）

API 文档由 `site/openapi/` 下的规范文件生成到 `site/docs/api/`（生成的 MDX 随站点一起编译，不要手改）：

```bash
# 修改 openapi 规范后，重新生成 API 文档（在 dev 容器内执行）
docker compose run --rm dev npm run gen-api

# 清空已生成的 API 文档
docker compose run --rm dev npm run clean-api

# 然后重启发布
docker compose restart docusaurus
```

## 导出 PDF（可选）

[docs-to-pdf](https://github.com/jean-humann/docs-to-pdf) 是独立 CLI（依赖 Chromium，故不写入项目依赖），在宿主机直接运行，针对已启动的站点生成：

```bash
npx docs-to-pdf docusaurus --initialDocURLs="http://localhost:8080/docs/intro" --version=3 --outputPDFFilename=docs.pdf
```

首次运行会自动下载 Chromium（国内网络较慢时可使用其官方 Docker 镜像 `ghcr.io/jean-humann/docs-to-pdf`）。

## 生产部署建议

- **修改对外端口**：编辑 `docker-compose.yml` 中 `ports: "8080:80"`
- **空目录自动填充样例**：`site/` 为空时，首次启动会自动复制镜像内置的样例站点（含配置）过来，便于参考修改；已有内容则绝不覆盖
- **升级 Docusaurus**：改 `.env` 的 `DOCUSAURUS_VERSION` → `pull` → `up -d`
- **国内环境**：默认已走 DaoCloud / 淘宝 / 阿里云源，无需额外配置
