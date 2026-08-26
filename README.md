# Docusaurus 生产 Docker（启动时编译，重启即发布）

基于 [Docusaurus](https://docusaurus.io/) 的生产级文档站点方案：

- **启动即编译**：容器启动时编译挂载的站点源码，然后由 Nginx 提供服务
- **改 md 即发布**：编辑文档后执行 `docker compose restart docusaurus`，无需重建镜像
- **版本即镜像 tag**：Docusaurus 升级 = 拉取新镜像
- **国内源**：DaoCloud 基础镜像 + 淘宝 npm 源 + 阿里云 alpine 源，全流程无外网压力

> 镜像内已预装全部依赖，启动编译很快：首次约 60 秒（含编译），有缓存时约 10 秒。

## 目录结构

```
docker-docusaurus/
├── docker-compose.yml   # 编排：生产服务 + 开发热更新
├── Dockerfile           # 生产镜像（node + nginx，启动时编译）
├── entrypoint.sh        # 启动脚本：同步源码 → 检测依赖变更 → 编译 → 启动 nginx
├── nginx.conf           # 生产级 nginx 配置（gzip + 缓存策略）
├── build.bat / build.sh # 维护者发版脚本（构建并推送镜像）
├── build-hub.bat        # 发布到 Docker Hub（版本取自 .env）
├── .env                 # 版本号 / 镜像名等配置
└── site/                # ★ 站点源码（docs、blog、配置都在这里）
    ├── docs/            # 文档 Markdown（日常只改这里）
    ├── docs/api/        # OpenAPI 生成的 API 文档（勿手改）
    └── openapi/         # OpenAPI 规范文件（API 文档的唯一数据源）
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

> 如果修改了 `site/package.json`（增删插件/依赖），重启时会自动重新安装依赖。

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
| `SITE_LOCALE` | 站点语言（默认 `zh-Hans`，影响 `<html lang>` 与界面文案） |
| `SITE_KEYWORDS` | SEO 关键词 |
| `SITE_NAVBAR_TITLE` | 导航栏标题（默认同 `SITE_TITLE`） |
| `SITE_FOOTER_COPYRIGHT` | 页脚版权文案 |

```bash
# 修改 docker-compose.yml 中的 x-site-config 后，重建容器即生效（无需重建镜像）
docker compose up -d docusaurus
```

> 自定义图标：把文件放到 `site/static/img/` 下（如 `logo.png`），并设置
> `SITE_FAVICON: /img/logo.png`。静态资源目录 `site/static/` 会原样发布到站点根路径。

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
docker compose up -d --build docusaurus
```

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
- **升级 Docusaurus**：改 `.env` 的 `DOCUSAURUS_VERSION` → `pull` → `up -d --build`
- **国内环境**：默认已走 DaoCloud / 淘宝 / 阿里云源，无需额外配置
